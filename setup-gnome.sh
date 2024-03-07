#!/bin/bash

# set themes to dark
gsettings set org.gnome.shell.ubuntu color-scheme prefer-dark
gsettings set org.gnome.desktop.interface gtk-theme Yaru-dark
gsettings set org.gnome.desktop.interface color-scheme prefer-dark 

# make windows open in the center
gsettings set org.gnome.mutter center-new-windows true

# enable hot corners
gsettings set org.gnome.desktop.interface enable-hot-corners true

# disable animations
gsettings set org.gnome.desktop.interface enable-animations false

# tweaks
sudo apt install gnome-tweaks

# install IBM Plex Mono and set it as default monospace font
sudo apt install fonts-ibm-plex fonts-jetbrains-mono fonts-inter -y 

# reset font caches
fc-cache -fv

# set interface fonts
gsettings set org.gnome.desktop.interface font-name "Inter Regular 11"
gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono Regular 11"

# setup font hinting
gsettings set org.gnome.desktop.interface font-hinting "full"
gsettings set org.gnome.desktop.interface font-antialiasing "rgba"

# setup nautilus
gsettings set org.gnome.nautilus.preferences default-sort-order 'mtime'

# nautilus-copy-path
mkdir -p ~/git
cd ~/git
git clone https://github.com/chr314/nautilus-copy-path.git
cd nautilus-copy-path
make install
cd ~

