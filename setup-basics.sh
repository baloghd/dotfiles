#!/bin/bash

sudo apt update

# install leftover configuration, if there is any
sudo dpkg --configure -a

# install git, curl, vim
sudo apt install git curl vim build-essential -y 

# install system tools
sudo apt install htop btop smartmontools net-tools lm-sensors dconf-editor -y 

# install nfs
sudo apt install nfs-common -y

# install keepassxc
sudo apt install keepassxc -y 

# install celluloid
sudo apt install gnome-mpv

# vscode
sudo snap install code --classic

# spotify
sudo snap install spotify 