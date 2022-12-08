#!/bin/bash

# set themes to dark
gsettings set org.gnome.shell.ubuntu color-scheme prefer-dark
gsettings set org.gnome.desktop.interface gtk-theme Yaru-dark
gsettings set org.gnome.desktop.interface color-scheme prefer-dark 

sudo apt update

# install leftover configuration, if there is any
sudo dpkg --configure -a

# install git, curl, vim
sudo apt install git curl vim -y 

# install and setup zsh
sudo apt install zsh zsh-common -y

yes | bash -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

# zsh syntax highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# zsh autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# install zsh plugins
sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions)/g' ~/.zshrc

# install IBM Plex Mono and set it as default monospace font
sudo apt install fonts-ibm-plex -y 

# install autojump
sudo apt install autojump
# add activation to .zshrc
echo ". /usr/share/autojump/autojump.sh" >> ~/.zshrc

# change shell to zsh
chsh -s $(which zsh)

# change zsh theme to kafeitu
sed -i "s/ZSH_THEME=.*/ZSH_THEME=\"kafeitu\"/g" ~/.zshrc

