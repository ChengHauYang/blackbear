#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/mac/blackbear_mac_common.sh
source "$SCRIPT_DIR/blackbear_mac_common.sh"

blackbear_mac_locate_repo
blackbear_mac_section "Installing format hook"

HOOK_FILE="$BLACKBEAR_DIR/.git/hooks/pre-commit"
if [[ -f "$HOOK_FILE" ]]; then
    echo "Pre-commit hook already exists at $HOOK_FILE"
else
    "$BLACKBEAR_DIR/scripts/install-format-hook.sh"
fi

echo
echo "HOOK=$HOOK_FILE"
echo "PRECHECK_INSTALLED=1"
