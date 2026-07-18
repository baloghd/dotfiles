---
title: create /pr slash command extension
claimed_by: 019f76f2
claimed_at: 2026-07-18T20:39:16.261Z
deps: []
epic: 
created: 2026-07-18T20:39:14.209Z
---

## Why

User wants a /pr command so they don't have to repeatedly tell pi to open a proper PR. This automates the full workflow from AGENTS.md: branch validation, pushing, PR creation with gh, and reports the URL.

## Acceptance

- `.pi/extensions/pr.ts` exists and is a valid pi extension
- Registers `/pr` command
- On invocation: guards against being on main, checks for dirty working tree, pushes branch, creates PR with `gh pr create --fill`
- Shows PR URL on success
- Register a `/prdone` command that merge-commits and deletes the branch
