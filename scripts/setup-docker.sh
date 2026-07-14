#!/bin/bash
# Install Docker CE from the official repo and configure rootless mode.

set -euo pipefail

. "$(dirname "$0")/../lib/detect-distro.sh"

case "$DISTRO" in
  fedora)
    $PKG_INSTALL dnf-plugins-core
    sudo dnf config-manager add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    $PKG_UPDATE
    ;;
  ubuntu|debian)
    $PKG_INSTALL ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL "https://download.docker.com/linux/$DISTRO/gpg" -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$DISTRO $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    $PKG_UPDATE
    ;;
esac

$PKG_INSTALL docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# uidmap is needed for docker rootless (provides newuidmap/newgidmap).
$PKG_INSTALL uidmap

dockerd-rootless-setuptool.sh install
docker run hello-world