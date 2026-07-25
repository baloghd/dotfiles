#!/bin/bash
# Install worktrunk (wt) — git worktree management CLI for parallel agent
# workflows. Config lives in home/.config/worktrunk, the pi skill in
# home/.agents/skills/worktrunk (both installed by install-home.sh).

set -euo pipefail

if command -v wt >/dev/null 2>&1; then
  echo "wt already installed: $(wt --version)"
  exit 0
fi

curl --proto '=https' --tlsv1.2 -LsSf \
  https://github.com/max-sixty/worktrunk/releases/latest/download/worktrunk-installer.sh | sh
