#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/mac/blackbear_mac_common.sh
source "$SCRIPT_DIR/blackbear_mac_common.sh"

blackbear_mac_guard init "$@"

blackbear_mac_activate
blackbear_mac_locate_repo
blackbear_mac_require_moose
blackbear_mac_env_exports

set -u

blackbear_mac_check_arch
blackbear_mac_check_sdk

cd "$MOOSE_DIR"

blackbear_mac_section "Configuring MOOSE for BlackBear"
echo "BLACKBEAR_DIR=$BLACKBEAR_DIR"
echo "MOOSE_DIR=$MOOSE_DIR ($BLACKBEAR_MOOSE_SOURCE)"

./configure "$@"

blackbear_mac_section "Configuration summary"
grep -E 'PREFIX|ENABLE_LIBTORCH|ENABLE_MFEM|ENABLE_NEML2|ENABLE_KOKKOS' conf_vars.mk || true

echo
echo "CONFIGURE_COMPLETED=1"
