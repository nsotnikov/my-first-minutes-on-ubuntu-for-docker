#!/bin/bash
#
# This script will work on Ubuntu 16.10, 16.04, 14.04
# Other distributions are not tested
#
# BUGS: https://github.com/nsotnikov/my-first-minutes-on-ubuntu-for-docker/issues
# COPYRIGHT: (c) 2017 Nikolaj Sotnikov 
#======================================================================================================================
# How to run the script:
#====================================================================================================================== 
# $ curl -sL https://git.io/vylnt | bash -s \
#   HOSTNAME="example.org" \
#   LANG="de_DE.UTF-8" \
#
#======================================================================================================================
# Aviable Variables:
#======================================================================================================================
#   HOSTNAME="example.org" \
#   LANG="de_DE.UTF-8"  \
#   TIMEZONE="Europe/Berlin"  \
#   USER="deploy"  \
#   PASSWORD="my_height_encrypted_password"  \
#   DIS_ROOT_SSH="Y"  \
#   INS_DOCKER="Y"  \
#   SECURITY="Y"  \
#   CUSTOM="echo hello world!"  \
#   SSH_KEY="ssh-rsa AAAAB3NzaCug..."  \
#
#======================================================================================================================
# Sources:
#======================================================================================================================
# https://github.com/sssmoves/web-init-script/tree/master/setup
# https://www.codelitt.com/blog/my-first-10-minutes-on-a-server-primer-for-securing-ubuntu/
# https://www.digitalocean.com/community/tutorials/how-to-configure-the-linux-firewall-for-docker-swarm-on-ubuntu-16-04
#
# Notes:
# curl -sL https://git.io/vylnt | bash -s -- arg1 arg2
# bash <( curl -sL https://git.io/vylnt ) arg1 arg2



clear

if [[ ! -e /etc/debian_version ]]; then
    echo "Looks like you aren't running this installer on a Debian or Ubuntu"
	  exit 
fi

if [[ $EUID -ne 0 ]]; then
	echo
	echo "This script must be run as root."
	echo
	exit
fi

if getent passwd $USER > /dev/null 2>&1; then
    echo "User [$USER] is already exists!"
    echo "Please change username and try again."
    echo
		exit
fi

function hide {
	# This function hides the output of a command unless the command fails
	# and returns a non-zero exit code.

	# Get a temporary file.
	OUTPUT=$(tempfile)

	# Execute command, redirecting stderr/stdout to the temporary file.
	$@ &> $OUTPUT

	# If the command failed, show the output that was captured in the temporary file.
	E=$?
	if [ $E != 0 ]; then
		# Something failed.
		echo
		echo FAILED: $@
		echo -----------------------------------------
		cat $OUTPUT
		echo -----------------------------------------
		exit $E
	fi

	# Remove temporary file.
	rm -f $OUTPUT
}
echo 
echo 
echo "WELCOME TO THE MY-FIRST-MINUTES-ON-UBUNTU-FOR-DOCKER SCRIPT"
echo
echo " If you have any issues, please visit:"
echo " https://github.com/nsotnikov/my-first-minutes-on-a-ubuntu-for-docker"
echo
echo "Performing apt update/upgrade and enable auto security updates."
echo "---------------------------------------------------------------"
printf "   - performing updates, please wait..."
hide apt-get -y update
printf "done\n"
printf "   - installing upgrades, please wait..."
hide apt-get -y upgrade
printf "done\n"
printf "   - installing unattended-upgrades..."
hide apt-get install unattended-upgrades
hide dpkg-reconfigure -f noninteractive --priority=low unattended-upgrades
printf "done.\n"

echo
echo "Change hostname, locale and timezone"
echo "---------------------------------------------------------------"
if [[ ! -z $HOSTNAME ]]; then
  printf "   - set hostname to $HOSTNAME..."
  hide hostname $HOSTNAME
  hide hostnamectl set-hostname $HOSTNAME
  printf "done.\n"
fi
if [[ ! -z $LANG ]]; then  
  printf "   - generating locales $LANG..."
  hide locale-gen $LANG
  hide update-locale $LANG
  printf "done.\n"
fi  
if [[ ! -z $TIMEZONE ]]; then
  printf "   - set timezone to $TIMEZONE..."
# to list all timezones run 
# $ timedatectl list-timezones
  hide timedatectl set-timezone $TIMEZONE
  printf "done.\n"
fi  


echo 
echo "New user, sudoers and ssh public key (if set)"
echo "---------------------------------------------------------------"
if [ ! -z $USER -a ! -z $PASSWORD ]; then  
  printf "   - adding new user [$USER]..."
  hide useradd -m -s /bin/bash -p $(openssl passwd -1 $PASSWORD) $USER
  printf "done.\n"
  printf "   - grant sudo privileges..."
  hide usermod -aG sudo $USER
  printf "done.\n"
  printf "   - disable password for sudo..."
  hide echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
  printf "done.\n"
  if [[ ! -z $SSH_KEY ]]; then
    printf "   - adding public key..."
    hide mkdir /home/$USER/.ssh
    hide echo $SSH_KEY > /home/$USER/.ssh/authorized_keys
    printf "done.\n"
    printf "   - change ssh key rights to..."
    hide chmod 400 /home/$USER/.ssh/authorized_keys
    hide chown $USER:$USER /home/$USER -R
    printf "done.\n"
  fi
fi
if [[ $DISABLE_ROOT_SSH == [yY] ]]; then  
  printf "   - turn off root ssh login..."
  sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
  printf "done.\n"
fi

if [[ $SECURITY == [yY] ]]; then
  echo
  echo "Enable firewall, update rules, installing useful tools like fail2ban\n"
  echo "---------------------------------------------------------------"
  printf "   - install firewall and useful tools like fail2ban, git..."
  hide apt-get -y install ufw fail2ban htop git
  printf "done.\n"
  printf "   - update firewall rules..."
  hide ufw allow 22
  hide ufw allow 80 # HTTP port
  hide ufw allow 443 # WHTTPS port
# Change to Enable default forward policy, only for old Docker versions.
# sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/g' /etc/default/ufw
  if [[ $INS_DOCKER == [yY] ]]; then
    hide ufw allow 2376 # Docker for client communication
    hide ufw allow 2377 # Docker cluster management communications
    hide ufw allow 4789 # Docker for overlay network traffic
    hide ufw allow 7946 # Docker for communication among nodes
  fi
  hide ufw default deny incoming
  hide ufw default allow outgoing
  hide service ufw restart
  printf "done.\n"
fi

if [[ $INS_DOCKER == [yY] ]]; then
	echo 
  echo "Installing Docker"
	echo "---------------------------------------------------------------"
  printf "   - installing prerequisites ..."
  hide apt-get -y install apt-transport-https ca-certificates curl 
  printf "done.\n"
  printf "   - adding pgp key and apt-repository..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  printf "done.\n"
  printf "   - performing apt update..."
  hide apt-get update
  printf "done.\n"
  printf "   - installind Docker, and enable autostart, pleasse wait..."
  hide apt-get -y --allow-unauthenticated install docker-ce
  hide groupadd docker
  hide usermod -aG docker $USER
  hide systemctl enable docker
  printf "done.\n"
fi

echo
echo "Clean up..."
echo "---------------------------------------------------------------"
printf "   - clean up install files, and history..."
hide apt-get -y autoremove --purge
hide apt-get -y clean
history -c && history -w
hide rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
printf "done.\n\n"

if [[ ! -z $LANG ]]; then
  echo "Run custom command"
  echo "---------------------------------------------------------------"
  echo
  bash -c "$CUSTOM"
fi
echo
echo "---------------------------------------------------------------"
echo "---------------------------------------------------------------"
echo
echo "   Completed!"
echo "   Dont forget to disable the password for ssh user login!"
echo
exit