---
title: De-duplicate to single scripts/ tree
claimed_by: 019f76cf
claimed_at: 2026-07-18T20:00:18.724Z
deps: []
epic: 
created: 2026-07-18T20:00:11.325Z
---

## Why

Phase 2 of the dotfiles refactor plan (PLAN.md). The fedora/ and ubuntu/ script trees were nearly identical except for package manager commands. Collapsed into a single scripts/ tree with lib/detect-distro.sh for distro detection. Completed in commit 846fdb2.

## Acceptance

- [x] lib/detect-distro.sh created with detection logic and exported vars
- [x] scripts/ created with 8 rewritten scripts using $PKG_INSTALL/$PKG_UPDATE
- [x] vscode/settings.json and screen-baby-profiles/screenset.sh lifted to repo root
- [x] fedora/ and ubuntu/ directories deleted
