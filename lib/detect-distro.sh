#!/bin/bash
# Detect the current distro and export package-manager variables.
#
# After sourcing, $DISTRO is one of: fedora, ubuntu, debian, unknown.
# $PKG_INSTALL / $PKG_UPDATE / $PKG_QUERY are pre-set when DISTRO is known;
# otherwise they're unset so callers can branch explicitly.
#
# Detection order:
#   1. /etc/os-release (the canonical source on modern systemd distros)
#   2. Fallback to legacy /etc/fedora-release and /etc/debian_version
#
# Usage:
#   # shellcheck source=lib/detect-distro.sh
#   . "$(dirname "$0")/../lib/detect-distro.sh"
#
#   case "$DISTRO" in
#     fedora) ... ;;
#     ubuntu|debian) ... ;;
#     *) echo "unsupported distro: $DISTRO" >&2; exit 1 ;;
#   esac

# Avoid double-sourcing.
if [ -n "${DOTFILES_DISTRO_LOADED:-}" ]; then
  return 0 2>/dev/null || true
fi
DOTFILES_DISTRO_LOADED=1

_distro_from_os_release() {
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}" in
      fedora) echo fedora ;;
      ubuntu|debian) echo "$ID" ;;
      *) echo "unknown" ;;
    esac
    return
  fi
  echo "unknown"
}

_distro_from_legacy() {
  if [ -r /etc/fedora-release ]; then
    echo fedora
  elif [ -r /etc/debian_version ]; then
    # /etc/debian_version exists on both Debian and Ubuntu; default to debian
    # and let os-release (above) disambiguate Ubuntu when available.
    echo debian
  else
    echo unknown
  fi
}

DISTRO="$(_distro_from_os_release)"
if [ "$DISTRO" = "unknown" ]; then
  DISTRO="$(_distro_from_legacy)"
fi
export DISTRO

case "$DISTRO" in
  fedora)
    PKG_INSTALL="sudo dnf install -y"
    PKG_UPDATE="sudo dnf check-update"
    PKG_QUERY="rpm -q"
    PKG_REPO_ADD="sudo dnf config-manager --add-repo"
    ;;
  ubuntu|debian)
    PKG_INSTALL="sudo apt-get install -y"
    PKG_UPDATE="sudo apt-get update"
    PKG_QUERY="dpkg -s"
    PKG_REPO_ADD="sudo tee /etc/apt/sources.list.d"
    ;;
  *)
    # Leave PKG_* unset; callers should branch on $DISTRO first.
    ;;
esac

export PKG_INSTALL PKG_UPDATE PKG_QUERY PKG_REPO_ADD