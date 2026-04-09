#!/bin/bash
USER=xcvb

sed "s/__USERNAME__/$USER/g" systemd/pass-dropbox.service > /etc/systemd/system/pass-dropbox.service

sed "s/__USERNAME__/$USER/g" systemd/obsidian-sync.service > /etc/systemd/system/obsidian-sync.service
