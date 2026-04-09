#!/bin/bash

gsettings set org.gnome.desktop.interface color-scheme prefer-dark

gsettings set org.gnome.mutter center-new-windows true

gsettings set org.gnome.desktop.interface enable-hot-corners true

gsettings set org.gnome.desktop.interface enable-animations false

gsettings set org.gnome.shell.extensions.ding show-home false

sudo dnf install gnome-tweaks

sudo dnf install google-noto-sans-mono-fonts google-noto-sans-fonts jetbrains-mono-fonts -y

fc-cache -fv

gsettings set org.gnome.desktop.interface font-name "Noto Sans Regular 11"
gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono Regular 11"

gsettings set org.gnome.desktop.interface font-hinting "full"
gsettings set org.gnome.desktop.interface font-antialiasing "rgba"

gsettings set org.gnome.nautilus.preferences default-sort-order 'mtime'
