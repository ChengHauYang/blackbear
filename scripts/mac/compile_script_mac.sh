#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

"$SCRIPT_DIR/blackbear.sh" all "$@"

echo
echo "COMPILE_SCRIPT_MAC_COMPLETED=1"
