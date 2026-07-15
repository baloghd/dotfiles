#!/bin/bash
# Install dotfiles from home/ into $HOME.
#
# Behavior:
#   - Files in home/ starting with '.' are symlinked to $HOME/$filename.
#   - home/.ssh/config.template is rendered (env-var substitution) into
#     $HOME/.ssh/config. Existing config is backed up before overwrite.
#   - Any existing target is backed up to <target>.bak.<timestamp> first.
#
# Flags:
#   --dry-run   Print actions without changing anything.
#   --force     Overwrite an existing target without backing up. Use with care.
#   --help      Show usage.

set -euo pipefail

DRY_RUN=0
FORCE=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run] [--force] [--help]

Install dotfiles from home/ into \$HOME.

Options:
  --dry-run   Print what would be done; make no changes.
  --force     Overwrite existing targets without backing them up.
  --help      Show this message.

Environment overrides for template rendering:
  DOTFILES_SSH_USERNAME    Substituted into __USERNAME__ (default: \$USER)
  DOTFILES_SSH_HOMELAB_HOST Substituted into __HOMELAB_HOST__ (default: homelab)

Backed-up targets are written to <target>.bak.<UTC timestamp>.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --force)   FORCE=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

# Resolve repo root (directory containing this script's parent).
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_SRC="$SCRIPT_DIR/home"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"

[ -d "$HOME_SRC" ] || { echo "error: home/ not found at $HOME_SRC" >&2; exit 1; }

# run <action> [args...] — prints the action; in dry-run mode does nothing.
run() {
  if [ "$DRY_RUN" = 1 ]; then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

# backup <path> — copies existing target to <path>.bak.<ts>, unless --force.
backup_if_exists() {
  local target="$1"
  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ "$FORCE" = 1 ]; then
      printf 'force: removing existing %s\n' "$target"
      run rm -f -- "$target"
    else
      local backup="${target}.bak.${TIMESTAMP}"
      printf 'backup: %s -> %s\n' "$target" "$backup"
      run mv -- "$target" "$backup"
    fi
  fi
}

# link_dotfile <src> <dst> — symlinks dst to src, backing up any existing dst.
link_dotfile() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    printf 'ok: %s already links to %s\n' "$dst" "$src"
    return
  fi
  backup_if_exists "$dst"
  mkdir -p "$(dirname "$dst")"
  printf 'link: %s -> %s\n' "$dst" "$src"
  run ln -s -- "$src" "$dst"
}

# render_template <src> <dst> — substitutes __VAR__ → env var (or default),
# writes to dst. Existing dst is backed up first.
render_template() {
  local src="$1" dst="$2"
  backup_if_exists "$dst"
  mkdir -p "$(dirname "$dst")"
  printf 'render: %s -> %s\n' "$src" "$dst"
  if [ "$DRY_RUN" = 1 ]; then
    return
  fi

  local content
  content="$(cat "$src")"

  # Substitute documented placeholders. Defaults come from $USER or hardcoded.
  local username="${DOTFILES_SSH_USERNAME:-$USER}"
  local homelab_host="${DOTFILES_SSH_HOMELAB_HOST:-homelab}"

  content="${content//__USERNAME__/$username}"
  content="${content//__HOMELAB_HOST__/$homelab_host}"

  printf '%s\n' "$content" > "$dst"
  chmod 600 "$dst"
}

# -- Process each entry in home/ --------------------------------------------
echo "==> Installing dotfiles from $HOME_SRC"
echo "    target: $HOME"
[ "$DRY_RUN" = 1 ] && echo "    mode: dry-run (no changes)"
echo

# Files at top level of home/ — symlink each as $HOME/<filename>.
shopt -s dotglob nullglob
for src in "$HOME_SRC"/.[!.]*; do
  [ -f "$src" ] || continue
  base="$(basename "$src")"
  # Skip the .ssh directory itself (handled by template case below).
  [ "$base" = ".ssh" ] && continue
  link_dotfile "$src" "$HOME/$base"
done

# Render the SSH config template into ~/.ssh/config.
ssh_template="$HOME_SRC/.ssh/config.template"
if [ -f "$ssh_template" ]; then
  render_template "$ssh_template" "$HOME/.ssh/config"
fi

echo
echo "==> Done."
echo "    Source files in $HOME_SRC; targets in $HOME."
echo "    Re-run this script any time after editing home/."

# Mark install completion so we can detect first-run vs subsequent.
if [ "$DRY_RUN" = 0 ]; then
  date -u +%Y-%m-%dT%H:%M:%SZ > "$HOME_SRC/.installed"
fi