#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/mac/blackbear_mac_common.sh
source "$SCRIPT_DIR/blackbear_mac_common.sh"

blackbear_mac_guard build "$@"

TARGET="app"

for arg in "$@"; do
    case "$arg" in
        --raw)
            export BLACKBEAR_MAC_RAW=1
            ;;
        --profile)
            export BLACKBEAR_MAC_PROFILE=1
            ;;
        app|unit|all)
            TARGET="$arg"
            ;;
        *)
            blackbear_mac_die "Unknown build option '$arg'. Use: app, unit, all, --raw, --profile"
            ;;
    esac
done

blackbear_mac_activate
blackbear_mac_locate_repo
blackbear_mac_require_moose
blackbear_mac_env_exports

set -u

blackbear_mac_check_arch
blackbear_mac_check_sdk

if ! blackbear_mac_configured; then
    blackbear_mac_die "MOOSE is not configured ($MOOSE_DIR/conf_vars.mk missing). Run ./scripts/mac/blackbear.sh init first."
fi

build_app()
{
    local method="${METHOD:-opt}"
    blackbear_mac_make_target app "$BLACKBEAR_DIR" "$method" "$BLACKBEAR_DIR/blackbear-$method"
}

build_unit()
{
    local method
    method="$(blackbear_mac_unit_method)"
    blackbear_mac_make_target unit "$BLACKBEAR_DIR/unit" "$method" "$BLACKBEAR_DIR/unit/blackbear-unit-$method"
}

case "$TARGET" in
    app)
        build_app
        ;;
    unit)
        build_unit
        ;;
    all)
        build_app
        build_unit
        ;;
esac

echo
echo "BUILD_COMPLETED=1"
