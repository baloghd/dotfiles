#!/bin/bash

sudo apt update

# install leftover configuration, if there is any
sudo dpkg --configure -a

# install git, curl, vim
sudo apt install git curl vim build-essential apt-transport-https -y 
gh auth login
gh auth setup-git
git config --global user.name "baloghd"                        
git config --global user.email "baloghd@sent.com"


# install system tools
sudo apt install htop btop smartmontools net-tools lm-sensors dconf-editor inotify-hookable inotify-tools -y 

# install nfs
sudo apt install nfs-common -y

# install keepassxc
sudo apt install keepassxc -y 

# install celluloid
sudo apt install gnome-mpv

# vscode
sudo apt-get install wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg

sudo apt install apt-transport-https
sudo apt update
sudo apt install code

cp vscode/settings.json ~/.config/Code/User

# install vscode extensions
# git graph
code --install-extension --force mhutchie.git-graph
# auto newline 
code --install-extension --force chang196700.newline
# json beautify
code --install-extension --force meezilla.json
# python
code --install-extension ms-python.debugpy
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
# systemd unit file
code --install-extension coolbear.systemd-unit-file


# spotify
sudo snap install spotify 

# noise generators
sudo apt install sox
alias bnoise="play -n synth brownnoise"
alias wnoise="play -n synth whitenoise"
