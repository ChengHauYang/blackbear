#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/mac/blackbear_mac_common.sh
source "$SCRIPT_DIR/blackbear_mac_common.sh"

# Doctor is read-only inspection: activation failure is non-fatal and must be reported.
blackbear_mac_activate 1 || true
blackbear_mac_locate_repo
blackbear_mac_env_exports
blackbear_mac_print_env

echo
echo "============================================"
echo " Doctor"
echo "============================================"

ARCH_OK=0
SDK_OK=0
CONDA_ENV_OK=0
VERSION_MATCH=0
MOOSE_OK=0
MOOSE_CONFIGURED=0
NEML_SUBMODULE_OK=0

TARGET_CONDA_ENV="${BLACKBEAR_CONDA_ENV:-moose}"

[[ "$(uname -m)" == "arm64" ]] && ARCH_OK=1
[[ -n "${SDKROOT:-}" && -d "${SDKROOT:-}" ]] && SDK_OK=1
[[ "${CONDA_DEFAULT_ENV:-}" == "$TARGET_CONDA_ENV" ]] && CONDA_ENV_OK=1
blackbear_mac_version_match && VERSION_MATCH=1
blackbear_mac_moose_ok && MOOSE_OK=1
blackbear_mac_configured && MOOSE_CONFIGURED=1
blackbear_mac_neml_submodule_ok && NEML_SUBMODULE_OK=1

echo "ARCH_OK=$ARCH_OK"
echo "SDK_OK=$SDK_OK"
echo "CONDA_ENV_OK=$CONDA_ENV_OK"
echo "VERSION_MATCH=$VERSION_MATCH"
echo "MOOSE_OK=$MOOSE_OK"
echo "MOOSE_SOURCE=$BLACKBEAR_MOOSE_SOURCE"
echo "MOOSE_CONFIGURED=$MOOSE_CONFIGURED"
echo "NEML_SUBMODULE_OK=$NEML_SUBMODULE_OK"

echo
echo "MPI_WRAPPERS:"
echo "mpicc:"
blackbear_mac_mpi_show_cmd mpicc || true
echo
echo "mpicxx:"
blackbear_mac_mpi_show_cmd mpicxx || true

echo
echo "TARGETS:"
unit_m="$(blackbear_mac_unit_method)"
for target in app_opt app_dbg "unit_${unit_m}"; do
    status="$(blackbear_mac_target_status "$target")"
    echo "${target}=${status}"
done

echo
if [[ "$CONDA_ENV_OK" -eq 0 ]]; then
    echo "RECOMMENDED_ACTION=activate_moose"
    echo "RECOMMENDED_COMMAND=conda activate $TARGET_CONDA_ENV"
elif [[ "$SDK_OK" -eq 0 ]]; then
    echo "RECOMMENDED_ACTION=install_sdk"
    echo "RECOMMENDED_COMMAND=\"\$CONDA_PREFIX/share/moose-compilers/scripts/get_mac_sdk.sh\""
elif [[ "$MOOSE_OK" -eq 0 ]]; then
    echo "RECOMMENDED_ACTION=locate_or_init_moose"
    echo "RECOMMENDED_COMMAND=git submodule update --init moose"
elif [[ "$VERSION_MATCH" -eq 0 ]]; then
    echo "RECOMMENDED_ACTION=sync_moose_version"
    echo "RECOMMENDED_COMMAND=conda update moose-dev"
elif [[ "$MOOSE_CONFIGURED" -eq 0 ]]; then
    echo "RECOMMENDED_ACTION=configure"
    echo "RECOMMENDED_COMMAND=./scripts/mac/blackbear.sh init"
elif [[ "$(blackbear_mac_target_status "app_${METHOD:-opt}")" != "BUILT" || "$(blackbear_mac_target_status "unit_${unit_m}")" != "BUILT" ]]; then
    echo "RECOMMENDED_ACTION=build"
    echo "RECOMMENDED_COMMAND=./scripts/mac/blackbear.sh build all"
else
    echo "RECOMMENDED_ACTION=build_or_test"
    echo "RECOMMENDED_COMMAND=./scripts/mac/blackbear.sh test all"
fi

exit 0
