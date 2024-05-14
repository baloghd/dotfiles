#!/bin/bash
USER=xcvb

# pass-dropbox
sed "s/__USERNAME__/$USER/g" systemd/pass-dropbox.service > /etc/systemd/system/pass-dropbox.service

# obsidian-sync
sed "s/__USERNAME__/$USER/g" systemd/obsidian-sync.service > /etc/systemd/system/obsidian-sync.service
