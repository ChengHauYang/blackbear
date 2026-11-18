#!/usr/bin/env bash
# shellcheck disable=SC2218 # False positive in ShellCheck 0.11.0 when functions call helpers before command substitutions
set -eo pipefail

# ==============================================================================
# BlackBear macOS Build & Test Harness CLI
# ==============================================================================
# Single state-aware entry point for building, testing, and verifying BlackBear
# on Apple Silicon macOS. Run './scripts/mac/blackbear.sh help' for usage.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/mac/blackbear_mac_common.sh
source "$SCRIPT_DIR/blackbear_mac_common.sh"

if [[ "${1:-}" == "-C" ]]; then
    [[ $# -ge 3 ]] || blackbear_mac_die "Usage: blackbear.sh -C <checkout> <command> [...]"
    BLACKBEAR_HARNESS_ROOT="$(git -C "$2" rev-parse --show-toplevel)" || \
        blackbear_mac_die "Invalid target checkout: $2"
    export BLACKBEAR_HARNESS_ROOT
    shift 2
fi

show_help()
{
    cat <<'EOF'
==============================================================================
BlackBear macOS Build & Test Harness CLI
==============================================================================
Single state-aware entry point for building, testing, and verifying BlackBear
on Apple Silicon macOS.

Usage:
  ./scripts/mac/blackbear.sh [-C checkout] <command> [target|scope] [options...]

Commands:
  dummy                      Living map: environment, MOOSE source, target state (+ why stale),
                             actual linked dylibs, and the next step (read-only)
  status, map                Aliases for dummy
  doctor                     Inspect toolchain, conda env, SDK, MOOSE, and build targets (read-only)
  init [configure flags...]  Configure MOOSE if missing (conf_vars.mk)
  build  [target] [-j N] [--raw] [--profile]
                             Build target: app (default), unit, or all.
                             Full make log goes to /tmp; only a summary is printed
                             (first error + short context on failure).
                             --raw streams make output; --profile adds TU/link counts.
  compile                    Alias for build
  run    <input.i> [...]     Run an input file with blackbear-<method>
  test   [scope] [pattern] [-j N] [--failed] [...]
                             Run tests without rebuilding: app, unit, or all (default).
                             A bare pattern selects app tests (run_tests --re); with
                             'unit' it is a gtest filter. --failed reruns only failures.
  verify [scope] [pattern] [-j N] [--raw] [--profile] [...]
                             Build the target, then run tests
  all    [-j N] [--raw]      Full pipeline: init -> build all -> test all
  format [base] [--check]    Format changed C++ files with Conda clang-format v21
  precheck                   Install git pre-commit clang-format hook
  logstat <log...> [--verbose]
                             Summarize solver convergence of run/test logs
  compare <file1> <file2> [--cmp SPEC] [--verbose]
                             Compare CSV or Exodus output with a compact summary
  exodiff <file1> <file2> [...]
                             Compare Exodus with the TestHarness default tolerances
  help [--agent]             Show this message or a short agent reference
  --help, -h                 Show this help message

Targets / Scopes:
  app                BlackBear application (blackbear-opt / blackbear-dbg)
  unit               BlackBear unit tests (unit/blackbear-unit-opt / -dbg)
  all                Both application and unit tests

Examples:
  ./scripts/mac/blackbear.sh dummy
  ./scripts/mac/blackbear.sh build app -j 8
  ./scripts/mac/blackbear.sh test actions
  ./scripts/mac/blackbear.sh test app --failed
  ./scripts/mac/blackbear.sh test unit MySampleTests*
  ./scripts/mac/blackbear.sh verify app concrete_ASR
  ./scripts/mac/blackbear.sh run test/tests/actions/test_actions.i

Output:
  Test runs end with one RESULT line (passed/failed/skipped/status/exit).
  init/build/test/verify/all/run hold a per-checkout lock, so concurrent runs
  fail fast with 'checkout busy' instead of corrupting a build.

Environment variables:
  METHOD               opt (default) | dbg
  UNIT_METHOD          Method for unit binary (default: METHOD)
  JOBS                 Parallel test jobs (default: 8; scripts/mac/harness.conf)
  BUILD_JOBS           Parallel compile jobs (default: JOBS)
  BLACKBEAR_MOOSE_DIR  Override MOOSE directory (default: ./moose submodule, else ../moose)
  BLACKBEAR_CONDA_ENV  Conda environment name (default: moose)
==============================================================================
EOF
}

show_agent_help()
{
    cat <<'EOF'
blackbear.sh [-C checkout] COMMAND: build/test harness for BlackBear (MOOSE app; uses ./moose or ../moose).
dummy: read-only living map; MOOSE source, target state + stale reason, actual dylib linkage, next step.
doctor: read-only check of conda, SDK, MOOSE version/config and target state.
build [app|unit|all] [-j N]: quiet build; log in /tmp, summary only. --raw streams, --profile counts TUs.
compile: alias for build.
run INPUT [args...]: preflight + execute blackbear-<method> -i INPUT.
test [app|unit|all] [pattern] [--failed]: no build; bare pattern = run_tests --re; unit = --gtest_filter.
verify SCOPE [pattern]: build then test; per-checkout lock excludes concurrent runs.
RESULT line reports counts, status and exit; ERROR also covers missing/empty results.
format [base] [--check]; logstat LOG --verbose; compare A B [--cmp SPEC]; exodiff A B.
EOF
}

if [[ $# -eq 0 ]]; then
    show_help
    exit 0
fi

COMMAND="$1"
shift

case "$COMMAND" in
    init|build|compile|test|verify|all|run|format)
        blackbear_mac_guard "$COMMAND" "$COMMAND" "$@"
        ;;
esac

case "$COMMAND" in
    --help|-h|help)
        if [[ "${1:-}" == "--agent" ]]; then
            show_agent_help
        else
            show_help
        fi
        exit 0
        ;;
    dummy|status|map)
        exec "$SCRIPT_DIR/dummy_mac.sh" "$@"
        ;;
    doctor)
        exec "$SCRIPT_DIR/doctor_mac.sh" "$@"
        ;;
    init)
        blackbear_mac_activate
        blackbear_mac_locate_repo
        blackbear_mac_require_moose
        blackbear_mac_env_exports

        if blackbear_mac_configured; then
            blackbear_mac_section "Initializing BlackBear Configuration"
            echo "MOOSE is already configured for BlackBear."
            echo "MOOSE_DIR ($BLACKBEAR_MOOSE_SOURCE): $MOOSE_DIR"
            echo "Configuration is up to date: $(blackbear_mac_conf_vars_file)"
            echo
            echo "INIT_COMPLETED=1"
            exit 0
        fi

        "$SCRIPT_DIR/configure_mac.sh" "$@"
        echo "INIT_COMPLETED=1"
        ;;
    build|compile)
        TARGET="app"
        BUILD_ARGS=()
        for arg in "$@"; do
            case "$arg" in
                app|unit|all) TARGET="$arg" ;;
                *) ;;
            esac
        done

        while [[ $# -gt 0 ]]; do
            case "$1" in
                -j)
                    [[ $# -ge 2 && "$2" =~ ^[1-9][0-9]*$ ]] || blackbear_mac_die "-j requires a positive integer."
                    export BUILD_JOBS="$2"
                    shift 2
                    ;;
                -j*)
                    [[ "${1#-j}" =~ ^[1-9][0-9]*$ ]] || blackbear_mac_die "-j requires a positive integer."
                    export BUILD_JOBS="${1#-j}"
                    shift
                    ;;
                app|unit|all)
                    shift
                    ;;
                *)
                    BUILD_ARGS+=("$1")
                    shift
                    ;;
            esac
        done

        exec "$SCRIPT_DIR/build_mac.sh" "$TARGET" ${BUILD_ARGS[@]+"${BUILD_ARGS[@]}"}
        ;;
    run)
        [[ $# -ge 1 ]] || \
            blackbear_mac_die "Usage: ./scripts/mac/blackbear.sh run <input.i> [MOOSE options...]"

        input="$1"
        shift

        blackbear_mac_activate
        blackbear_mac_locate_repo
        blackbear_mac_require_moose
        blackbear_mac_env_exports

        exe="$(blackbear_mac_target_exe app)"
        [[ -f "$input" ]] || blackbear_mac_die "Input file not found: $input"
        [[ -x "$exe" ]] || \
            blackbear_mac_die "Executable not found: $exe. Run './scripts/mac/blackbear.sh build app' first."

        blackbear_mac_check_preflight "$exe" || exit 1

        blackbear_mac_section "Running $input"
        exec "$exe" -i "$input" "$@"
        ;;
    test)
        exec "$SCRIPT_DIR/test_mac.sh" "$@"
        ;;
    verify)
        SCOPE="all"
        BUILD_ARGS=()
        TEST_ARGS=()

        if [[ $# -gt 0 ]]; then
            case "$1" in
                app|unit|all)
                    SCOPE="$1"
                    shift
                    ;;
                -*)
                    ;;
                *)
                    # A bare pattern selects app tests, matching 'test'.
                    SCOPE="app"
                    ;;
            esac
        fi

        while [[ $# -gt 0 ]]; do
            case "$1" in
                -j)
                    [[ $# -ge 2 && "$2" =~ ^[1-9][0-9]*$ ]] || blackbear_mac_die "-j requires a positive integer."
                    export JOBS="$2" BUILD_JOBS="$2"
                    shift 2
                    ;;
                -j*)
                    [[ "${1#-j}" =~ ^[1-9][0-9]*$ ]] || blackbear_mac_die "-j requires a positive integer."
                    export JOBS="${1#-j}" BUILD_JOBS="${1#-j}"
                    shift
                    ;;
                --raw|--profile)
                    BUILD_ARGS+=("$1")
                    shift
                    ;;
                *)
                    TEST_ARGS+=("$1")
                    shift
                    ;;
            esac
        done

        blackbear_mac_activate
        blackbear_mac_locate_repo
        blackbear_mac_require_moose
        blackbear_mac_env_exports

        blackbear_mac_section "Verifying BlackBear ($SCOPE)"

        if ! blackbear_mac_configured; then
            echo "Configuration missing. Running init..."
            "$SCRIPT_DIR/configure_mac.sh"
        fi

        "$SCRIPT_DIR/build_mac.sh" "$SCOPE" ${BUILD_ARGS[@]+"${BUILD_ARGS[@]}"}
        "$SCRIPT_DIR/test_mac.sh" "$SCOPE" ${TEST_ARGS[@]+"${TEST_ARGS[@]}"}

        echo
        echo "VERIFY_COMPLETED=1"
        ;;
    all)
        BUILD_ARGS=()
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -j)
                    [[ $# -ge 2 && "$2" =~ ^[1-9][0-9]*$ ]] || blackbear_mac_die "-j requires a positive integer."
                    export JOBS="$2" BUILD_JOBS="$2"
                    shift 2
                    ;;
                -j*)
                    [[ "${1#-j}" =~ ^[1-9][0-9]*$ ]] || blackbear_mac_die "-j requires a positive integer."
                    export JOBS="${1#-j}" BUILD_JOBS="${1#-j}"
                    shift
                    ;;
                --raw|--profile)
                    BUILD_ARGS+=("$1")
                    shift
                    ;;
                *)
                    blackbear_mac_die "Unknown all option '$1'."
                    ;;
            esac
        done

        blackbear_mac_activate
        blackbear_mac_locate_repo
        blackbear_mac_require_moose
        blackbear_mac_env_exports

        blackbear_mac_section "Running full end-to-end pipeline (all)"

        if ! blackbear_mac_configured; then
            echo "Configuration missing. Configuring MOOSE..."
            "$SCRIPT_DIR/configure_mac.sh"
        else
            echo "Configuration is valid."
        fi

        "$SCRIPT_DIR/build_mac.sh" all ${BUILD_ARGS[@]+"${BUILD_ARGS[@]}"}
        "$SCRIPT_DIR/test_mac.sh" all

        echo
        echo "ALL_COMPLETED=1"
        ;;
    format)
        blackbear_mac_activate
        blackbear_mac_locate_repo
        exec python3 "$SCRIPT_DIR/../harness/control.py" format "$BLACKBEAR_DIR" "$@"
        ;;
    precheck)
        exec "$SCRIPT_DIR/init_precheck.sh" "$@"
        ;;
    logstat)
        exec python3 "$SCRIPT_DIR/../harness/cli.py" logstat "$@"
        ;;
    compare)
        blackbear_mac_activate
        blackbear_mac_locate_repo
        blackbear_mac_env_exports
        exec python3 "$SCRIPT_DIR/../harness/cli.py" compare "$@"
        ;;
    exodiff)
        [[ $# -ge 2 ]] || blackbear_mac_die "Usage: blackbear.sh exodiff <file1> <file2> [exodiff options...]"
        blackbear_mac_activate
        blackbear_mac_locate_repo
        blackbear_mac_env_exports
        exec python3 "$SCRIPT_DIR/../harness/cli.py" exodiff "$@"
        ;;
    *)
        echo "ERROR: Unknown command '$COMMAND'. See './scripts/mac/blackbear.sh --help'" >&2
        exit 1
        ;;
esac
