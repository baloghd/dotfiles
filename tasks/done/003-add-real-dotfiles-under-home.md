---
title: Add real dotfiles under home/
claimed_by: 019f76cf
claimed_at: 2026-07-18T20:00:20.633Z
deps: []
epic: 
created: 2026-07-18T20:00:11.325Z
---

## Why

Phase 3 of the dotfiles refactor plan (PLAN.md). The repo was named dotfiles but had zero actual dotfiles. Added home/ directory with starter dotfiles and install-home.sh. Completed in commit 846fdb2.

## Acceptance

- [x] home/{.gitconfig,.gitignore_global,.tmux.conf,.ssh/config.template,.vimrc} created
- [x] install-home.sh created with idempotent symlink/copy logic, --dry-run, and timestamped backups
