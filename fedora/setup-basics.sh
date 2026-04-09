#!/bin/bash

sudo dnf check-update

sudo dnf install git gh curl vim make gcc-c++ openssh-server -y
gh auth login
gh auth setup-git
git config --global user.name "baloghd"                        
git config --global user.email "baloghd@sent.com"

sudo dnf install htop btop smartmontools net-tools lm-sensors dnfdragora inotify-tools -y

touch /home/$USER/.config/rclone/rclone.conf

sudo dnf install nfs-utils -y

sudo dnf install fuse fuse-devel -y

sudo dnf install keepassxc -y

sudo dnf install celluloid -y

sudo dnf install ripgrep -y

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf check-update
sudo dnf install code -y

mkdir -p ~/.config/Code/User
cp vscode/settings.json ~/.config/Code/User

code --install-extension mhutchie.git-graph
code --install-extension chang196700.newline
code --install-extension meezilla.json
code --install-extension ms-python.debugpy
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension coolbear.systemd-unit-file
code --install-extension johnpapa.vscode-peacock
code --install-extension ms-azuretools.vscode-docker
code --install-extension rangav.vscode-thunder-client
code --install-extension ms-toolsai.jupyter
code --install-extension ms-toolsai.jupyter-keymap
code --install-extension ms-toolsai.jupyter-renderers
code --install-extension ms-toolsai.vscode-jupyter-cell-tags
code --install-extension ms-toolsai.vscode-jupyter-slideshow

flatpak install flathub com.spotify.Client -y

sudo dnf install sox -y
alias bnoise="amixer -q set Master 20% && play -n synth brownnoise"
alias wnoise="amixer -q set Master 20% && play -n synth whitenoise"
