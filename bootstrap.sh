#!/bin/bash

# The ultimate bootstrap script for a new Ubuntu installation
#
# Inspired by:
# * https://github.com/LukeSmithxyz/voidrice 
# * https://github.com/wubbl0rz/dotfiles
# * https://github.com/yboetz/motd

# define colors
RED='\033[0;31m'
PRIMARY='\033[0;33m'
GREEN='\033[1;32m'
NC='\033[0m' # no color

# check is script is run as root
[[ $EUID != 0 ]] && printf "${RED}script has to be run as root${NC}\n" && exit 1

# check OS
[[ "$(awk -F= '/^NAME/{print $2}' /etc/os-release)" != "\"Ubuntu\"" ]] && printf "${RED}script only runs under Ubuntu${NC}\n" && exit 1

# install updates
printf "${PRIMARY}Install updates${NC}\n\n"
apt update -q
apt dist-upgrade -y -q

# install basic tools
printf "\n${PRIMARY}Install basic tools${NC}\n\n"
apt install vim git htop unattended-upgrades zsh zsh-syntax-highlighting lolcat figlet neofetch -y -q

# copy .vimrc
printf "\n${PRIMARY}Create .vimrc${NC} "
cp .bootstrap-defaults/vimrc /etc/vim/vimrc.local && printf " ${GREEN}OK${NC}\n"

# copy .zshrc
printf "${PRIMARY}Create .zshrc${NC} "
cp .bootstrap-defaults/zshrc ~/.zshrc && printf " ${GREEN}OK${NC}\n"

# enable zsh
printf "${PRIMARY}Changing shell to zsh ${NC}"

chsh -s "$(whereis zsh | cut -d' ' -f2)" && printf " ${GREEN}OK${NC}\n"

printf "${PRIMARY}Change shell for other user? Type username or leave empty for no action: ${GREEN}"
read user
printf "${NC}"

if [ -n "$user" ]; then
    if id "$user" >/dev/null 2>&1; then
        usermod --shell "$(whereis zsh | cut -d' ' -f2)" $user 2> /dev/null
        cp .bootstrap-defaults/zshrc "$(getent passwd "johannes" | cut -d: -f6)/.zshrc"
    else
        printf "${RED}user $user does not exist!${NC}\n"
    fi
fi
 
# enable unattended upgrades
printf "${PRIMARY}Enabling unattended upgrades${NC}\n"

sed -i '/\/\/\t"${distro_id}:${distro_codename}-updates";/s/^\/\//  /g' /etc/apt/apt.conf.d/50unattended-upgrades

echo "APT::Periodic::Update-Package-Lists "1";" > /etc/apt/apt.conf.d/20auto-upgrades
echo "APT::Periodic::Download-Upgradeable-Packages "1";" >> /etc/apt/apt.conf.d/20auto-upgrades
echo "APT::Periodic::AutocleanInterval "7";" >> /etc/apt/apt.conf.d/20auto-upgrades
echo "APT::Periodic::Unattended-Upgrade "1";" >> /etc/apt/apt.conf.d/20auto-upgrades

# create fancy MOTD
printf "${PRIMARY}Creating fancy MOTD${NC}\n"

chmod -x /etc/update-motd.d/00-header
chmod -x /etc/update-motd.d/10-help-text
chmod -x /etc/update-motd.d/50-motd-news
chmod -x /etc/update-motd.d/50-landscape-sysinfo

cp .bootstrap-defaults/10-hostname-color /etc/update-motd.d/ && chmod +x /etc/update-motd.d/10-hostname-color
cp .bootstrap-defaults/20-sysinfo /etc/update-motd.d/ && chmod +x /etc/update-motd.d/20-sysinfo
cp .bootstrap-defaults/35-diskspace /etc/update-motd.d/ && chmod +x /etc/update-motd.d/35-diskspace

# finished
printf "\n${PRIMARY}Your system is ready!${NC}\n"
