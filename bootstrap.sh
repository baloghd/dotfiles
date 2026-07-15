#!/bin/bash
# Bootstrap a fresh Fedora or Ubuntu workstation by running all setup
# scripts in scripts/ in the documented order.
#
# Usage:
#   ./bootstrap.sh [--dry-run] [--skip <name>] [--only <name>]
#
#   --dry-run    Print what would run; do not execute setup scripts.
#   --skip NAME  Skip the script named scripts/setup-NAME.sh.
#                (e.g. --skip docker skips scripts/setup-docker.sh)
#   --only NAME  Run only the script named scripts/setup-NAME.sh.
#                Repeat to run several. (e.g. --only zsh --only gnome)
#   --yes        Skip the confirmation prompt at the start.
#   --help       Show usage.
#
# After this script completes, run install-home.sh to symlink/copy
# the dotfiles under home/ into $HOME.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

DRY_RUN=0
ASSUME_YES=0
SKIP=()
ONLY=()

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run] [--skip NAME]... [--only NAME]... [--yes] [--help]

Bootstraps a Fedora or Ubuntu workstation by running scripts/setup-*.sh
in order. Destructive steps (none currently) would prompt before running.

Options:
  --dry-run        Print what would run; do not execute setup scripts.
  --skip NAME      Skip scripts/setup-NAME.sh (repeatable).
  --only NAME      Run only scripts/setup-NAME.sh (repeatable; --skip ignored).
  --yes            Assume yes at the confirmation prompt.
  --help           Show this message.

Available scripts (see scripts/README.md for the run order):
EOF
  for f in "$SCRIPTS_DIR"/setup-*.sh; do
    [ -f "$f" ] || continue
    printf '  %s\n' "$(basename "$f")"
  done
}

# Parse args.
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --yes|-y)  ASSUME_YES=1 ;;
    --skip)    SKIP+=("$2"); shift ;;
    --only)    ONLY+=("$2"); shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown flag: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# Source the distro detector early so we can show what we're on.
# shellcheck source=lib/detect-distro.sh
. "$SCRIPT_DIR/lib/detect-distro.sh"

echo "==> Distro: $DISTRO"
if [ "$DISTRO" = "unknown" ]; then
  echo "error: unsupported distro (no /etc/os-release match)." >&2
  exit 1
fi
echo "==> Package manager: $PKG_INSTALL"
echo

# Documented run order. bootstrap.sh does not invent order — adjust this list
# when adding new scripts.
ORDER=(
  setup-basics
  setup-gnome
  setup-zsh
  setup-docker
  setup-python
  setup-rclone
)

# Normalize a user-supplied NAME to the canonical "setup-NAME" form.
# Accepts both "docker" and "setup-docker" on the command line.
normalize_name() {
  case "$1" in
    setup-*) printf '%s\n' "$1" ;;
    *)       printf 'setup-%s\n' "$1" ;;
  esac
}

# Apply --only / --skip filtering.
if [ ${#ONLY[@]} -gt 0 ]; then
  FILTERED=()
  for raw in "${ONLY[@]}"; do
    name="$(normalize_name "$raw")"
    found=0
    for o in "${ORDER[@]}"; do
      if [ "$o" = "$name" ]; then
        FILTERED+=("$o"); found=1; break
      fi
    done
    if [ "$found" = 0 ]; then
      echo "warning: --only $raw not in run order, ignoring" >&2
    fi
  done
  ORDER=("${FILTERED[@]}")
else
  FILTERED=()
  for o in "${ORDER[@]}"; do
    skip=0
    for raw in "${SKIP[@]}"; do
      name="$(normalize_name "$raw")"
      [ "$o" = "$name" ] && skip=1
    done
    [ "$skip" = 0 ] && FILTERED+=("$o")
  done
  ORDER=("${FILTERED[@]}")
fi

if [ ${#ORDER[@]} -eq 0 ]; then
  echo "error: no scripts to run after applying --only/--skip filters." >&2
  exit 1
fi

echo "==> Will run (in order):"
for name in "${ORDER[@]}"; do
  printf '    scripts/%s.sh\n' "$name"
done
echo

if [ "$DRY_RUN" = 0 ] && [ "$ASSUME_YES" = 0 ]; then
  printf "Continue? [y/N] "
  read -r ans
  case "$ans" in
    y|Y|yes|Yes|YES) ;;
    *) echo "aborted."; exit 0 ;;
  esac
fi

echo
FAIL=0
for name in "${ORDER[@]}"; do
  script="$SCRIPTS_DIR/${name}.sh"
  if [ ! -f "$script" ]; then
    echo "!! missing: $script" >&2
    FAIL=1
    continue
  fi
  echo "==> $name"
  if [ "$DRY_RUN" = 1 ]; then
    echo "[dry-run] would execute: $script"
  else
    if ! bash "$script"; then
      echo "!! $name failed (exit $?)" >&2
      FAIL=1
    fi
  fi
  echo
done

if [ "$FAIL" = 1 ]; then
  echo "==> Bootstrap finished with errors. Inspect output above." >&2
  exit 1
fi

cat <<EOF
==> Bootstrap done.

Next steps:
  1. Run ./install-home.sh to symlink your dotfiles into \$HOME.
  2. Run scripts/zshrc-additions.sh sourcing (or append its contents
     to ~/.zshrc).
  3. Log out / log in so the zsh shell change takes effect.
EOF