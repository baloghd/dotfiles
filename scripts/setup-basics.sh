#!/bin/bash
# Install core CLI tools, VS Code, fonts, and Spotify.
#
# Re-running is safe: package managers skip already-installed packages,
# git config commands are idempotent, vscode install-extension is a no-op
# on subsequent runs.

set -euo pipefail

. "$(dirname "$0")/../lib/detect-distro.sh"

# -- System update -----------------------------------------------------------
$PKG_UPDATE

case "$DISTRO" in
  ubuntu|debian)
    # Pick up any half-applied dpkg state from a prior interrupted run.
    sudo dpkg --configure -a || true
    ;;
esac

# -- Core CLI tools ----------------------------------------------------------
$PKG_INSTALL git gh curl vim openssh-server
case "$DISTRO" in
  fedora)         $PKG_INSTALL make gcc-c++ ;;
  ubuntu|debian)  $PKG_INSTALL build-essential apt-transport-https ;;
esac

gh auth login
gh auth setup-git
git config --global user.name "baloghd"
git config --global user.email "baloghd@sent.com"

# -- System monitoring / fs tools -------------------------------------------
case "$DISTRO" in
  fedora)         $PKG_INSTALL htop btop smartmontools net-tools lm-sensors dnfdragora inotify-tools ;;
  ubuntu|debian)  $PKG_INSTALL htop btop smartmontools net-tools lm-sensors dconf-editor inotify-hookable inotify-tools ;;
esac

# rclone placeholder config (real config lives in ~/.config/rclone/rclone.conf)
mkdir -p "$HOME/.config/rclone"
touch "$HOME/.config/rclone/rclone.conf"

# -- NFS client + FUSE for AppImages ----------------------------------------
case "$DISTRO" in
  fedora)         $PKG_INSTALL nfs-utils fuse fuse-devel ;;
  ubuntu|debian)  $PKG_INSTALL nfs-common libfuse2 ;;
esac

# -- Apps --------------------------------------------------------------------
$PKG_INSTALL keepassxc

# Media player (package name differs by distro)
case "$DISTRO" in
  fedora)         $PKG_INSTALL celluloid ;;
  ubuntu|debian)  $PKG_INSTALL gnome-mpv ;;
esac

$PKG_INSTALL ripgrep

# -- VS Code: official repo + install ---------------------------------------
case "$DISTRO" in
  fedora)
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo tee /etc/yum.repos.d/vscode.repo > /dev/null <<'REPO'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
REPO
    $PKG_UPDATE
    $PKG_INSTALL code
    ;;
  ubuntu|debian)
    $PKG_INSTALL wget gpg
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor > /tmp/packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
      | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm -f /tmp/packages.microsoft.gpg
    $PKG_INSTALL apt-transport-https
    $PKG_UPDATE
    $PKG_INSTALL code
    ;;
esac

# -- VS Code settings + extensions ------------------------------------------
mkdir -p "$HOME/.config/Code/User"
cp "$(dirname "$0")/../vscode/settings.json" "$HOME/.config/Code/User/settings.json"

EXTENSIONS=(
  mhutchie.git-graph
  chang196700.newline
  meezilla.json
  ms-python.debugpy
  ms-python.python
  ms-python.vscode-pylance
  coolbear.systemd-unit-file
  johnpapa.vscode-peacock
  ms-azuretools.vscode-docker
  rangav.vscode-thunder-client
  ms-toolsai.jupyter
  ms-toolsai.jupyter-keymap
  ms-toolsai.jupyter-renderers
  ms-toolsai.vscode-jupyter-cell-tags
  ms-toolsai.vscode-jupyter-slideshow
)
for ext in "${EXTENSIONS[@]}"; do
  code --install-extension "$ext" || true
done

# -- Spotify (different package source per distro) -------------------------
case "$DISTRO" in
  fedora)
    flatpak install flathub com.spotify.Client -y
    ;;
  ubuntu|debian)
    curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg \
      | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
    echo "deb http://repository.spotify.com stable non-free" \
      | sudo tee /etc/apt/sources.list.d/spotify.list > /dev/null
    sudo apt-get update && sudo apt-get install spotify-client -y
    ;;
esac

# -- sox for noise generators ----------------------------------------------
$PKG_INSTALL sox

echo
echo "Note: noise aliases (bnoise, wnoise) live in scripts/zshrc-additions.sh."
echo "Source it from your ~/.zshrc to make them available interactively."