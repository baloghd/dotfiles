---
title: Scope cleanup — move homelab bits out
claimed_by: 019f76cf
claimed_at: 2026-07-18T20:00:14.400Z
deps: []
epic: 
created: 2026-07-18T20:00:11.323Z
---

## Why

Phase 1 of the dotfiles refactor plan (PLAN.md). Homelab-coupled pieces (setup-mounts, setup-hosts, systemd services, syncthing, yt-vpn) needed to move to the homelab repo. Completed in commit 846fdb2.

## Acceptance

- [x] Homelab files moved to homelab repo
- [x] Files git-rm'd from dotfiles repo
- [x] Commit with message "move homelab-coupled configs to homelab repo"
