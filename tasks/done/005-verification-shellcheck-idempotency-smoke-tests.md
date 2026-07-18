---
title: Verification — shellcheck, idempotency, smoke tests
claimed_by: 019f76cf
claimed_at: 2026-07-18T20:00:24.522Z
deps: []
epic: 
created: 2026-07-18T20:00:11.326Z
---

## Why

Phase 5 of the dotfiles refactor plan (PLAN.md). Static checks, distro detection tests, idempotency verification, and manual smoke testing. Verified through CI and local testing.

## Acceptance

- [x] Static checks: shellcheck passes, bash -n passes on all scripts
- [x] Distro detection works on Fedora and Ubuntu
- [x] install-home.sh idempotent (second run reports "already linked")
- [x] CI workflow runs on every push/PR
