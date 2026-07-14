#!/bin/bash
# Install rclone (used by systemd services in homelab repo to sync vault/pass db).

set -euo pipefail

. "$(dirname "$0")/../lib/detect-distro.sh"

$PKG_INSTALL rclone