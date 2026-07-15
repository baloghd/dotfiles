#!/bin/bash
# GNOME desktop tweaks: theme, fonts, animations, hot corners, nautilus.

set -euo pipefail

. "$(dirname "$0")/../lib/detect-distro.sh"

# -- Theme: dark mode --------------------------------------------------------
case "$DISTRO" in
  ubuntu|debian)
    gsettings set org.gnome.shell.ubuntu color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface gtk-theme Yaru-dark
    ;;
esac
gsettings set org.gnome.desktop.interface color-scheme prefer-dark

# -- Window behavior --------------------------------------------------------
gsettings set org.gnome.mutter center-new-windows true
gsettings set org.gnome.desktop.interface enable-hot-corners true
gsettings set org.gnome.desktop.interface enable-animations false
gsettings set org.gnome.shell.extensions.ding show-home false

# -- Tweaks tool + fonts -----------------------------------------------------
$PKG_INSTALL gnome-tweaks

case "$DISTRO" in
  fedora)
    $PKG_INSTALL google-noto-sans-mono-fonts google-noto-sans-fonts jetbrains-mono-fonts
    INTERFACE_FONT="Noto Sans Regular 11"
    ;;
  ubuntu|debian)
    $PKG_INSTALL fonts-ibm-plex fonts-jetbrains-mono fonts-inter
    INTERFACE_FONT="Inter Regular 11"
    ;;
esac

fc-cache -fv

gsettings set org.gnome.desktop.interface font-name "$INTERFACE_FONT"
gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono Regular 11"
gsettings set org.gnome.desktop.interface font-hinting "full"
gsettings set org.gnome.desktop.interface font-antialiasing "rgba"

# -- Nautilus ----------------------------------------------------------------
gsettings set org.gnome.nautilus.preferences default-sort-order 'mtime'

# nautilus-copy-path extension
mkdir -p "$HOME/git"
if [ ! -d "$HOME/git/nautilus-copy-path" ]; then
  git clone https://github.com/chr314/nautilus-copy-path.git "$HOME/git/nautilus-copy-path"
  ( cd "$HOME/git/nautilus-copy-path" && make install )
fi