# My first minutes on a Ubuntu server to secure and prepare for Docker
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Ftikkerei%2Fvps-first-run.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Ftikkerei%2Fvps-first-run?ref=badge_shield)


Simple unix shell script to improve the security of your Ubuntu server and install Docker.    

This shell script can do:
  - performing apt update/upgrade of your server
  - enable automatic security upgrades, unattended-upgrades
  - change hostname, locales and timezone (Variables: HOSTNAME, LANG, TIMEZONE)
  - add new user, public ssh key and enable sudo (Variables: USER, PASSWORD, SSH_KEY)
  - disallow root ssh access (Variable: DIS_ROOT_SSH)
  - install Docker, add user to docker group (Variable: INS_DOCKER)
  - setup firewall ufw, update rules and install useful tools like file2ban (Variable: SECURITY)
  - if set run custom command (Variable: CUSTOM)
  - cleanup

Please read [the script](https://raw.githubusercontent.com/nsotnikov/my-first-minutes-on-ubuntu-for-docker/master/ubuntu-first-run.sh) before running. 

## Get Running
1. Run the script, please see the possible [options](#options).  to use below.    
2. Once it ends, please try to login with your ssh key and if succesfull then [disable password](#disable-user-ssh-password-login).   

```sh
curl -sL https://git.io/vylnt | bash -s -- \
HOSTNAME="example.org" \
LANG="de_DE.UTF-8" \
TIMEZONE="Europe/Berlin" \
USER="deploy" \
PASSWORD="my_height_encrypted_password" \
DIS_ROOT_SSH="Y" \
INS_DOCKER="Y" \
SECURITY="Y" \
CUSTOM="echo hello world!" \
SSH_KEY="ssh-rsa AAAAB3NzaCug..." 
```

If you dont not need to change/install some feature just skip the variables.     
An example to change only the hostname and run custom command:
```sh
curl -sL https://git.io/vylnt | bash -s -- \
HOSTNAME="example.org" \
CUSTOM="apt-get install -y apache" 
```
## Options
Set the hostname of you server:
HOSTNAME="example.org" \

Set language and timezone:
LANG="de_DE.UTF-8" \
TIMEZONE="Europe/Berlin" \

Add new user, set password and add ssh key:
USER="deploy" \
PASSWORD="my_height_encrypted_password" \
SSH_KEY="ssh-rsa AAAAB3NzaCug..." 

Disable ssh login for root:
DIS_ROOT_SSH="Y" \

Install docker:
INS_DOCKER="Y" \

Imrove security:
SECURITY="Y" \

Any custom command:
CUSTOM="echo hello world!" \

## Disable user ssh password login
Login to the server as new user with your ssh key!    
If the key authentication was succesfull, please disable password for the new user. 
 
Open the SSH daemon configuration:
```sh
$ sudo nano /etc/ssh/sshd_config
```

Find the line that specifies PasswordAuthentication, uncomment it by deleting the preceding #, then change its value to "no".     
It should look like this after you have made the change:
```
PasswordAuthentication no
```

When you are finished making your changes, save and close the file using the method we went over earlier (CTRL-X, then Y, then ENTER).
Type this to reload the SSH daemon:
```sh
$ sudo systemctl reload sshd
```

## Author

Nikolaj Sotnikov - [nsotnikov@gmail.com](mailto:nsotnikov@gmail.com)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details


[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Ftikkerei%2Fvps-first-run.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Ftikkerei%2Fvps-first-run?ref=badge_large)