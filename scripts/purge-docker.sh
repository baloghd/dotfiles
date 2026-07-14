#!/bin/bash
# Completely uninstall Docker. DESTRUCTIVE — review before running.

set -euo pipefail

. "$(dirname "$0")/../lib/detect-distro.sh"

sudo systemctl stop docker

case "$DISTRO" in
  fedora)         sudo dnf remove -y docker-ce docker-ce-cli containerd.io ;;
  ubuntu|debian)  sudo apt-get purge -y docker-ce docker-ce-cli containerd.io ;;
esac

sudo rm -rf /etc/docker
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm -rf /var/run/docker.sock
sudo rm -rf /usr/bin/docker
sudo rm -rf /usr/bin/docker-compose

sudo groupdel docker || true

echo "Docker purged successfully."