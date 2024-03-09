#!/bin/bash

# pass-dropbox
USER=$(whoami)
sed "s/__USERNAME__/$USER/g" systemd/pass-dropbox.service > /etc/systemd/system/pass-dropbox.service
