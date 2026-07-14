#!/bin/bash
# Install pip for Python 3.

set -euo pipefail

. "$(dirname "$0")/../lib/detect-distro.sh"

$PKG_INSTALL python3-pip