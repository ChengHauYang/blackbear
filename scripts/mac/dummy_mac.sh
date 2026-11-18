#!/usr/bin/env bash
# shellcheck disable=SC2218 # False positive in ShellCheck 0.11.0 when functions call helpers before command substitutions
set -eo pipefail

# ==============================================================================
# BlackBear "living map": a read-only dashboard answering at a glance:
# "where are the pieces, what is healthy, what does each binary actually link,
#  and what should I run next".
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/mac/blackbear_mac_common.sh
source "$SCRIPT_DIR/blackbear_mac_common.sh"

for arg in "$@"; do
    case "$arg" in
        -h|--help)
            echo "Usage: blackbear.sh dummy"
            echo "Read-only dashboard: environment, MOOSE source, target state (+ why stale),"
            echo "actual MOOSE/PETSc/NEML linkage, and the recommended next step."
            exit 0
            ;;
        *)
            blackbear_mac_die "Unknown dummy option '$arg'."
            ;;
    esac
done

# Read-only inspection: activation failure is reported, not fatal.
blackbear_mac_activate 1 || true
blackbear_mac_locate_repo
blackbear_mac_env_exports

set -u

BLACKBEAR_TARGET_STALE_REASON=""; BLACKBEAR_TARGET_EXE=""; BLACKBEAR_LINK_BROKEN=0
ARCH_OK=0; SDK_OK=0; CONDA_ENV_OK=0
MOOSE_OK=0; MOOSE_CONFIGURED=0; NEML_SUBMODULE_OK=0
TARGET_CONDA_ENV="${BLACKBEAR_CONDA_ENV:-moose}"

[[ "$(uname -m)" == "arm64" ]] && ARCH_OK=1
[[ -n "${SDKROOT:-}" && -d "${SDKROOT:-}" ]] && SDK_OK=1
[[ "${CONDA_DEFAULT_ENV:-}" == "$TARGET_CONDA_ENV" ]] && CONDA_ENV_OK=1
blackbear_mac_moose_ok && MOOSE_OK=1
blackbear_mac_configured && MOOSE_CONFIGURED=1
blackbear_mac_neml_submodule_ok && NEML_SUBMODULE_OK=1

echo
echo "============================================"
echo " BlackBear Living Map"
echo "============================================"

# ----------------------------------------------------------------------------
# 1. Environment & Sources
# ----------------------------------------------------------------------------
echo
echo "--- [1] Environment & Sources ---"
echo "  Repo         : ${BLACKBEAR_DIR/#$HOME/~}"
echo "  Branch/commit: $(git -C "$BLACKBEAR_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?') @ $(git -C "$BLACKBEAR_DIR" rev-parse --short HEAD 2>/dev/null || echo '?')$(git -C "$BLACKBEAR_DIR" diff --quiet 2>/dev/null || echo ' (dirty)')"
echo "  Conda (build): ${CONDA_DEFAULT_ENV:-<none>} (want: $TARGET_CONDA_ENV)"
if [[ "$MOOSE_OK" -eq 1 ]]; then
    moose_branch="$(git -C "$MOOSE_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
    moose_commit="$(git -C "$MOOSE_DIR" rev-parse --short HEAD 2>/dev/null || echo '?')"
    echo "  MOOSE        : ${MOOSE_DIR/#$HOME/~} ($BLACKBEAR_MOOSE_SOURCE: $moose_branch @ $moose_commit)"
    if [[ "$BLACKBEAR_MOOSE_SOURCE" == "submodule" ]]; then
        moose_pin="$(git -C "$BLACKBEAR_DIR" rev-parse HEAD:moose 2>/dev/null || echo '?')"
        moose_head="$(git -C "$MOOSE_DIR" rev-parse HEAD 2>/dev/null || echo '?')"
        if [[ "$moose_pin" != "?" && "$moose_head" != "?" && "$moose_pin" != "$moose_head" ]]; then
            echo "                 [OUT OF SYNC: checkout ${moose_head:0:8} != pinned ${moose_pin:0:8}]"
        fi
    fi
else
    echo "  MOOSE        : MISSING (checked $BLACKBEAR_DIR/moose and $(dirname "$BLACKBEAR_DIR")/moose)"
fi
echo "  contrib/neml : $([[ $NEML_SUBMODULE_OK -eq 1 ]] && echo 'INITIALIZED' || echo 'not initialized (optional; builds without NEML)')"
echo "  Configured   : $([[ $MOOSE_CONFIGURED -eq 1 ]] && echo "yes ($(blackbear_mac_conf_vars_file | sed "s#$HOME#~#"))" || echo 'no -> blackbear.sh init')"

# ----------------------------------------------------------------------------
# 2. Targets: state + why stale + what they ACTUALLY link
# ----------------------------------------------------------------------------
echo
echo "--- [2] Target Executables ---"
ready_count=0; stale_count=0; missing_count=0
stale_targets=(); missing_targets=()
any_link_broken=0

describe_target()
{
    local key="$1" label="$2"
    blackbear_mac_target_status "$key" >/dev/null
    local status="$BLACKBEAR_TARGET_STATUS"
    local exe="$BLACKBEAR_TARGET_EXE"
    echo "  * $label: [$status]"
    echo "      path : ${exe/#$HOME/~}"
    case "$status" in
        BUILT)
            ready_count=$((ready_count + 1))
            echo "      links:"
            local links_out
            links_out="$(blackbear_mac_describe_links "$exe")"
            echo "$links_out" | sed 's/^/    /'
            [[ "$links_out" == *MISSING* ]] && any_link_broken=1
            ;;
        STALE)
            stale_count=$((stale_count + 1))
            stale_targets+=("$key")
            echo "      why  : ${BLACKBEAR_TARGET_STALE_REASON:-unknown}"
            local links_out
            links_out="$(blackbear_mac_describe_links "$exe")"
            if [[ "$links_out" == *MISSING* ]]; then
                any_link_broken=1
                echo "      links (broken):"
                echo "$links_out" | grep -E 'MISSING|additional' | sed 's/^/    /'
            fi
            ;;
        *)
            missing_count=$((missing_count + 1))
            missing_targets+=("$key")
            echo "      note : not built yet"
            ;;
    esac
    echo
}

unit_m="$(blackbear_mac_unit_method)"
describe_target "app_${METHOD:-opt}" "app (blackbear-${METHOD:-opt})"
describe_target "unit_${unit_m}" "unit (blackbear-unit-${unit_m})"

# ----------------------------------------------------------------------------
# 3. Progress map
# ----------------------------------------------------------------------------
echo "--- [3] Progress ---"
ok="[x]"; warn="[!]"; todo="[ ]"
[[ "$ARCH_OK" -eq 1 && "$SDK_OK" -eq 1 ]] && s1="$ok" || s1="$warn"
[[ "$CONDA_ENV_OK" -eq 1 ]] && s2="$ok" || s2="$warn"
[[ "$MOOSE_OK" -eq 1 ]] && s3="$ok" || s3="$warn"
[[ "$MOOSE_CONFIGURED" -eq 1 ]] && s4="$ok" || s4="$warn"
if [[ "$ready_count" -eq 2 && "$any_link_broken" -eq 0 ]]; then
    s5="$ok"
elif [[ "$stale_count" -gt 0 || "$any_link_broken" -eq 1 ]]; then
    s5="$warn"
else
    s5="$todo"
fi
echo "  $s1 1. Apple Silicon arm64 + macOS SDK"
echo "  $s2 2. Conda env ($TARGET_CONDA_ENV)"
echo "  $s3 3. MOOSE checkout ($BLACKBEAR_MOOSE_SOURCE)"
echo "  $s4 4. MOOSE configuration (conf_vars.mk)"
echo "  $s5 5. Executables ($ready_count/2 built, $stale_count stale, $missing_count missing)"

# ----------------------------------------------------------------------------
# 4. Next step
# ----------------------------------------------------------------------------
echo
echo "--- [4] Next step ---"
if [[ "$SDK_OK" -eq 0 ]]; then
    echo "  SDK missing -> \"\$CONDA_PREFIX/share/moose-compilers/scripts/get_mac_sdk.sh\""
elif [[ "$CONDA_ENV_OK" -eq 0 ]]; then
    echo "  Wrong/no conda env -> conda activate $TARGET_CONDA_ENV"
elif [[ "$MOOSE_OK" -eq 0 ]]; then
    echo "  MOOSE missing -> check ../moose or run: git submodule update --init moose"
elif [[ "$MOOSE_CONFIGURED" -eq 0 ]]; then
    echo "  Not configured -> ./scripts/mac/blackbear.sh init"
elif [[ "$any_link_broken" -eq 1 ]]; then
    echo "  A linked library no longer resolves (e.g. MOOSE module_loader or Conda bump)."
    echo "  -> ./scripts/mac/blackbear.sh build all"
elif [[ "$stale_count" -gt 0 ]]; then
    echo "  Stale target(s) -> rebuild before testing:"
    for t in "${stale_targets[@]}"; do
        case "$t" in
            app*)  echo "    ./scripts/mac/blackbear.sh build app" ;;
            unit*) echo "    ./scripts/mac/blackbear.sh build unit" ;;
        esac
    done
elif [[ "$missing_count" -gt 0 ]]; then
    echo "  Build missing target(s):"
    for t in "${missing_targets[@]}"; do
        case "$t" in
            app*)  echo "    ./scripts/mac/blackbear.sh build app" ;;
            unit*) echo "    ./scripts/mac/blackbear.sh build unit" ;;
        esac
    done
else
    echo "  All built and up to date. Run tests:"
    echo "    ./scripts/mac/blackbear.sh test app"
    echo "    ./scripts/mac/blackbear.sh test unit"
fi
echo "============================================"

exit 0
