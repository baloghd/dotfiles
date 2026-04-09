#!/bin/bash

sudo systemctl stop docker

sudo dnf remove -y docker-ce docker-ce-cli containerd.io

sudo rm -rf /etc/docker

sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm -rf /var/run/docker.sock

sudo rm -rf /usr/bin/docker
sudo rm -rf /usr/bin/docker-compose

sudo groupdel docker

echo "Docker purged successfully."
