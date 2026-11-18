#!/usr/bin/env bash
# shellcheck disable=SC2218 # False positive in ShellCheck 0.11.0 when functions call helpers before command substitutions
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/mac/blackbear_mac_common.sh
source "$SCRIPT_DIR/blackbear_mac_common.sh"

blackbear_mac_guard test "$@"

SCOPE=""
PATTERN=""
EXTRA_ARGS=()
HAS_RE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        app|unit|all)
            if [[ -z "$SCOPE" && -z "$PATTERN" ]]; then
                SCOPE="$1"
            else
                EXTRA_ARGS+=("$1")
            fi
            shift
            ;;
        -j)
            [[ $# -ge 2 && "$2" =~ ^[1-9][0-9]*$ ]] || blackbear_mac_die "-j requires a positive integer."
            JOBS="$2"
            shift 2
            ;;
        -j*)
            [[ "${1#-j}" =~ ^[1-9][0-9]*$ ]] || blackbear_mac_die "-j requires a positive integer."
            JOBS="${1#-j}"
            shift
            ;;
        --failed)
            EXTRA_ARGS+=("--failed-tests")
            shift
            ;;
        --re|--re=*)
            HAS_RE=1
            EXTRA_ARGS+=("$1")
            shift
            ;;
        -*)
            EXTRA_ARGS+=("$1")
            shift
            ;;
        *)
            if [[ -z "$PATTERN" ]]; then
                PATTERN="$1"
            else
                EXTRA_ARGS+=("$1")
            fi
            shift
            ;;
    esac
done

# A bare pattern targets the regression suite (the common case).
if [[ -z "$SCOPE" ]]; then
    if [[ -n "$PATTERN" ]]; then SCOPE="app"; else SCOPE="all"; fi
fi

blackbear_mac_activate
blackbear_mac_locate_repo
blackbear_mac_require_moose
blackbear_mac_env_exports

set -u

blackbear_mac_check_arch
blackbear_mac_check_sdk

if [[ -n "$PATTERN" ]]; then
    case "$SCOPE" in
        app)
            [[ "$HAS_RE" -eq 0 ]] || blackbear_mac_die "Give either a pattern or --re, not both."
            EXTRA_ARGS=("--re" "$PATTERN" ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"})
            ;;
        unit)
            EXTRA_ARGS=("--gtest_filter=$PATTERN" ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"})
            ;;
        all)
            blackbear_mac_die "A pattern needs a single scope: 'test app <pattern>' or 'test unit <pattern>'."
            ;;
    esac
fi

HARNESS_CONTROL="$SCRIPT_DIR/../harness/control.py"

run_app_tests()
{
    local method="${METHOD:-opt}"
    local app_target="app_${method}"
    blackbear_mac_target_status "$app_target" >/dev/null
    local app_status="$BLACKBEAR_TARGET_STATUS"

    if [[ "$app_status" == "MISSING" ]]; then
        blackbear_mac_die "Application binary (blackbear-${method}) is missing. Run './scripts/mac/blackbear.sh build app' or './scripts/mac/blackbear.sh verify app'."
    elif [[ "$app_status" == "STALE" ]]; then
        blackbear_mac_die "Application binary (blackbear-${method}) is stale (${BLACKBEAR_TARGET_STALE_REASON:-source or MOOSE modified}). Run './scripts/mac/blackbear.sh build app' or './scripts/mac/blackbear.sh verify app'."
    fi

    blackbear_mac_check_preflight "$BLACKBEAR_DIR/blackbear-${method}" || exit 1

    blackbear_mac_section "Running BlackBear application tests (method: $method, jobs: $JOBS)"

    cd "$BLACKBEAR_DIR"

    local rc=0
    python3 "$HARNESS_CONTROL" test app \
        ./run_tests -j"$JOBS" \
        ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"} || rc=$?

    [[ "$rc" -eq 0 ]] || exit "$rc"
    echo "APP_TESTS_COMPLETED=1"
}

run_unit_tests()
{
    local unit_m
    unit_m="$(blackbear_mac_unit_method)"
    blackbear_mac_target_status "unit_${unit_m}" >/dev/null
    local unit_status="$BLACKBEAR_TARGET_STATUS"

    if [[ "$unit_status" == "MISSING" ]]; then
        blackbear_mac_die "Unit binary (unit/blackbear-unit-${unit_m}) is missing. Run './scripts/mac/blackbear.sh build unit' or './scripts/mac/blackbear.sh verify unit'."
    elif [[ "$unit_status" == "STALE" ]]; then
        blackbear_mac_die "Unit binary (unit/blackbear-unit-${unit_m}) is stale (${BLACKBEAR_TARGET_STALE_REASON:-source or MOOSE modified}). Run './scripts/mac/blackbear.sh build unit' or './scripts/mac/blackbear.sh verify unit'."
    fi

    local unit_exe="$BLACKBEAR_DIR/unit/blackbear-unit-${unit_m}"
    blackbear_mac_check_preflight "$unit_exe" --gtest_list_tests || exit 1

    blackbear_mac_section "Running BlackBear unit tests ($unit_exe)"

    cd "$BLACKBEAR_DIR/unit"

    local tmp_out rc
    tmp_out="$(mktemp /tmp/blackbear-unit-run-XXXXXX.log)"

    set +e
    python3 "$HARNESS_CONTROL" test --unit unit \
        "$unit_exe" ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"} 2>&1 | tee "$tmp_out"
    rc="${PIPESTATUS[0]}"
    set -e

    if [[ "$rc" -ne 0 ]]; then
        blackbear_mac_diagnose_dyld_error "$tmp_out" || true
    fi
    rm -f "$tmp_out"

    [[ "$rc" -eq 0 ]] || exit "$rc"
    echo "UNIT_TESTS_COMPLETED=1"
}

case "$SCOPE" in
    app)
        run_app_tests
        ;;
    unit)
        run_unit_tests
        ;;
    all)
        run_app_tests
        run_unit_tests
        ;;
    *)
        blackbear_mac_die "Unknown test scope '$SCOPE'. Use: app, unit, all"
        ;;
esac

echo
echo "TEST_COMPLETED=1"
