#!/bin/bash

# Stop Docker service
sudo systemctl stop docker

# Remove Docker packages installed via apt
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io

# Remove Docker configuration files
sudo rm -rf /etc/docker

# Remove Docker-related files and directories
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm -rf /var/run/docker.sock

# Remove Docker executables from the PATH (optional)
sudo rm -rf /usr/bin/docker
sudo rm -rf /usr/bin/docker-compose

# Remove Docker group (optional)
sudo groupdel docker

# Remove Docker user (optional)
# sudo userdel docker

# Remove Docker user home directory (optional)
# sudo rm -rf /home/docker

echo "Docker purged successfully."
