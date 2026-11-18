#!/usr/bin/env bash

# Common helpers for BlackBear on Apple Silicon macOS.
# This file is meant to be sourced by other scripts.
# shellcheck disable=SC2218 # False positive in ShellCheck 0.11.0 when functions call helpers before command substitutions

blackbear_mac_section()
{
    echo
    echo "============================================"
    echo " $*"
    echo "============================================"
}

blackbear_mac_die()
{
    local msg="$1"
    local code=1
    if [[ "$#" -ge 2 && "$2" =~ ^[0-9]+$ ]]; then
        code="$2"
    elif [[ "$#" -gt 1 ]]; then
        msg="$*"
    fi
    echo
    echo "ERROR: $msg" >&2
    exit "$code"
}

blackbear_mac_activate()
{
    local non_fatal="${1:-0}"
    local had_nounset=0
    if [[ "$-" == *u* ]]; then
        had_nounset=1
    fi

    # Do not require nounset during Conda activation.
    # Conda compiler hooks may reference unset backup variables.
    set +u

    local target_env="${BLACKBEAR_CONDA_ENV:-moose}"

    if ! typeset -f conda >/dev/null 2>&1; then
        local _conda_sh
        for _conda_sh in ${CONDA_EXE:+"$(dirname "$(dirname "$CONDA_EXE")")/etc/profile.d/conda.sh"} \
                         "$HOME/miniforge/etc/profile.d/conda.sh" \
                         "$HOME/miniforge3/etc/profile.d/conda.sh" \
                         "$HOME/miniconda3/etc/profile.d/conda.sh" \
                         "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh"; do
            if [[ -f "$_conda_sh" ]]; then
                # shellcheck source=/dev/null
                . "$_conda_sh"
                break
            fi
        done
        unset _conda_sh
    fi

    # Unset stale environment variables from older setups before resolving MOOSE_DIR.
    unset MOOSE_DIR LIBMESH_DIR LIBMESH_SRC_DIR HDF5_STR

    if ! typeset -f conda >/dev/null 2>&1; then
        if [[ "$had_nounset" -eq 1 ]]; then set -u; else set +u; fi
        if [[ "$non_fatal" -eq 1 ]]; then
            return 1
        fi
        blackbear_mac_die "Could not find conda shell function or conda.sh to activate environment."
    fi

    if ! conda activate "$target_env" 2>/dev/null; then
        if [[ "$had_nounset" -eq 1 ]]; then set -u; else set +u; fi
        if [[ "$non_fatal" -eq 1 ]]; then
            return 1
        fi
        blackbear_mac_die "Could not activate conda environment '$target_env'"
    fi

    unset MOOSE_DIR

    if [[ "$had_nounset" -eq 1 ]]; then
        set -u
    else
        set +u
    fi
    return 0
}

blackbear_mac_locate_repo()
{
    local script_source="${BASH_SOURCE[0]:-}"
    local script_dir=""
    if [[ -n "$script_source" && -e "$script_source" ]]; then
        script_dir="$(cd "$(dirname "$script_source")" && pwd -P)"
    fi

    if [[ -n "${BLACKBEAR_HARNESS_ROOT:-}" ]]; then
        BLACKBEAR_DIR="$(cd "$BLACKBEAR_HARNESS_ROOT" && pwd -P)"
    elif [[ -n "$script_dir" ]]; then
        BLACKBEAR_DIR="$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null || true)"
    fi

    if [[ -z "${BLACKBEAR_DIR:-}" ]]; then
        BLACKBEAR_DIR="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || true)"
    fi

    if [[ -z "${BLACKBEAR_DIR:-}" || ! -f "$BLACKBEAR_DIR/Makefile" ]]; then
        blackbear_mac_die "Could not locate BlackBear repository root. Run from inside BlackBear repository."
    fi

    export BLACKBEAR_DIR

    # Resolve MOOSE_DIR matching BlackBear's Makefile/run_tests precedence,
    # while allowing explicit override via BLACKBEAR_MOOSE_DIR.
    local parent_dir
    parent_dir="$(dirname "$BLACKBEAR_DIR")"
    if [[ -n "${BLACKBEAR_MOOSE_DIR:-}" ]]; then
        MOOSE_DIR="$BLACKBEAR_MOOSE_DIR"
        BLACKBEAR_MOOSE_SOURCE="override"
    elif [[ -f "$BLACKBEAR_DIR/moose/framework/Makefile" ]]; then
        MOOSE_DIR="$BLACKBEAR_DIR/moose"
        BLACKBEAR_MOOSE_SOURCE="submodule"
    elif [[ -f "$parent_dir/moose/framework/Makefile" ]]; then
        MOOSE_DIR="$parent_dir/moose"
        BLACKBEAR_MOOSE_SOURCE="sibling"
    else
        MOOSE_DIR=""
        BLACKBEAR_MOOSE_SOURCE="missing"
    fi

    export BLACKBEAR_MOOSE_SOURCE
    if [[ -n "$MOOSE_DIR" ]]; then
        export MOOSE_DIR
    else
        unset MOOSE_DIR
    fi
}

blackbear_mac_require_moose()
{
    if [[ -z "${MOOSE_DIR:-}" || ! -f "$MOOSE_DIR/framework/Makefile" ]]; then
        blackbear_mac_die "Could not locate MOOSE (checked $BLACKBEAR_DIR/moose and $(dirname "$BLACKBEAR_DIR")/moose). Set BLACKBEAR_MOOSE_DIR or initialize the moose submodule."
    fi
}

blackbear_mac_env_exports()
{
    local conf_file="${SCRIPT_DIR:-$BLACKBEAR_DIR/scripts/mac}/harness.conf"
    if [[ -f "$conf_file" ]]; then
        # shellcheck source=/dev/null
        source "$conf_file"
    fi

    if [[ -n "${CONDA_PREFIX:-}" ]]; then
        export PATH="$CONDA_PREFIX/bin:$PATH"
    fi
    export METHOD="${METHOD:-opt}"
    export UNIT_METHOD="${UNIT_METHOD:-$METHOD}"
    export JOBS="${JOBS:-${BLACKBEAR_DEFAULT_JOBS:-8}}"
    export BUILD_JOBS="${BUILD_JOBS:-$JOBS}"
    if [[ -n "${MOOSE_DIR:-}" ]]; then
        export MOOSE_DIR
    fi
}

blackbear_mac_check_arch()
{
    local arch
    arch="$(uname -m)"

    if [[ "$arch" != "arm64" ]]; then
        blackbear_mac_die "This script expects Apple Silicon arm64. Detected: $arch"
    fi
}

blackbear_mac_check_sdk()
{
    if [[ -z "${SDKROOT:-}" || ! -d "${SDKROOT:-}" ]]; then
        blackbear_mac_die "MOOSE macOS SDK is not configured. Run: \"\$CONDA_PREFIX/share/moose-compilers/scripts/get_mac_sdk.sh\""
    fi
}

blackbear_mac_mpi_show_cmd()
{
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "<not found>"
        return 1
    fi

    if "$1" --showme:command >/dev/null 2>&1; then
        "$1" --showme:command
    else
        "$1" -show 2>/dev/null || echo "<unable to run show>"
    fi
}

blackbear_mac_print_env()
{
    blackbear_mac_section "Environment"

    echo "BLACKBEAR_DIR=${BLACKBEAR_DIR:-}"
    echo "MOOSE_DIR=${MOOSE_DIR:-<missing>} (${BLACKBEAR_MOOSE_SOURCE:-unknown})"
    echo "ARCH=$(uname -m)"
    echo "CONDA_PREFIX=${CONDA_PREFIX:-}"
    echo "SDKROOT=${SDKROOT:-}"
    echo "METHOD=${METHOD:-opt}"
    echo "UNIT_METHOD=${UNIT_METHOD:-opt}"
    echo "JOBS=${JOBS:-8}"
    echo
    echo "CC=${CC:-}"
    echo "CXX=${CXX:-}"
    echo
    echo "python=$(command -v python || true)"
    echo "mpicc=$(command -v mpicc || true)"
    echo "mpicxx=$(command -v mpicxx || true)"
}

blackbear_mac_versioner_output()
{
    if [[ -n "${MOOSE_DIR:-}" && -f "$MOOSE_DIR/scripts/versioner.py" ]]; then
        python "$MOOSE_DIR/scripts/versioner.py" 2>/dev/null || true
    fi
}

blackbear_mac_conda_moose_version()
{
    if [[ -n "${CONDA_PREFIX:-}" && -d "$CONDA_PREFIX/conda-meta" ]]; then
        local meta_file
        for meta_file in "$CONDA_PREFIX"/conda-meta/moose-dev-*.json; do
            if [[ -f "$meta_file" ]]; then
                basename "$meta_file" | sed -E 's/^moose-dev-([0-9.]+)-.*/\1/'
                return 0
            fi
        done
    fi

    if command -v conda >/dev/null 2>&1; then
        conda list --no-pip '^moose-dev$' 2>/dev/null | awk '$1=="moose-dev"{print $2}'
    fi
}

blackbear_mac_version_match()
{
    local v_py v_conda
    v_py="$(blackbear_mac_versioner_output)"
    v_conda="$(blackbear_mac_conda_moose_version)"

    [[ -n "$v_py" && "$v_py" == "$v_conda" ]]
}

blackbear_mac_moose_ok()
{
    [[ -n "${MOOSE_DIR:-}" && -f "$MOOSE_DIR/framework/Makefile" ]]
}

blackbear_mac_neml_submodule_ok()
{
    [[ -n "${BLACKBEAR_DIR:-}" && -f "$BLACKBEAR_DIR/contrib/neml/CMakeLists.txt" ]]
}

blackbear_mac_conf_vars_file()
{
    if [[ -n "${MOOSE_DIR:-}" ]]; then
        echo "$MOOSE_DIR/conf_vars.mk"
    else
        echo ""
    fi
}

blackbear_mac_configured()
{
    local conf
    conf="$(blackbear_mac_conf_vars_file)"
    [[ -n "$conf" && -f "$conf" ]]
}

blackbear_mac_unit_method()
{
    if [[ -n "${UNIT_METHOD:-}" ]]; then
        echo "$UNIT_METHOD"
    else
        echo "${METHOD:-opt}"
    fi
}

blackbear_mac_target_dir()
{
    case "$1" in
        app)
            echo "$BLACKBEAR_DIR"
            ;;
        unit)
            echo "$BLACKBEAR_DIR/unit"
            ;;
        *)
            blackbear_mac_die "Unknown target '$1'. Use: app, unit, all"
            ;;
    esac
}

blackbear_mac_target_exe()
{
    case "$1" in
        app_opt)
            echo "$BLACKBEAR_DIR/blackbear-opt"
            ;;
        app_dbg)
            echo "$BLACKBEAR_DIR/blackbear-dbg"
            ;;
        app)
            echo "$BLACKBEAR_DIR/blackbear-${METHOD:-opt}"
            ;;
        unit_opt)
            echo "$BLACKBEAR_DIR/unit/blackbear-unit-opt"
            ;;
        unit_dbg)
            echo "$BLACKBEAR_DIR/unit/blackbear-unit-dbg"
            ;;
        unit)
            echo "$BLACKBEAR_DIR/unit/blackbear-unit-$(blackbear_mac_unit_method)"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Staleness bounds:
# - app targets (blackbear-opt, blackbear-dbg) check:
#     $BLACKBEAR_DIR/Makefile, blackbear.mk, contrib/neml.mk
#     $BLACKBEAR_DIR/src, include, test/src, test/include (and contrib/neml if present)
#     $MOOSE_DIR/framework/libmoose-<method>.dylib (if built)
# - unit targets (blackbear-unit-<method>) check:
#     $BLACKBEAR_DIR/unit/Makefile, $BLACKBEAR_DIR/Makefile, blackbear.mk, contrib/neml.mk
#     $BLACKBEAR_DIR/unit/src, unit/include, src (excluding main.C), include (and contrib/neml if present)
#     $MOOSE_DIR/framework/libmoose-<method>.dylib (if built)
# Returns one of: BUILT, STALE, MISSING.
# Also sets BLACKBEAR_TARGET_STALE_REASON and BLACKBEAR_TARGET_EXE.
blackbear_mac_target_status()
{
    local target="$1"
    local exe=""
    local target_method="${METHOD:-opt}"
    local src_dirs=()
    BLACKBEAR_TARGET_STALE_REASON=""
    BLACKBEAR_TARGET_EXE=""
    BLACKBEAR_TARGET_STATUS="UNKNOWN"

    case "$target" in
        app_opt|blackbear-opt)
            target_method="opt"
            exe="$BLACKBEAR_DIR/blackbear-opt"
            src_dirs=("$BLACKBEAR_DIR/src" "$BLACKBEAR_DIR/include" "$BLACKBEAR_DIR/test/src" "$BLACKBEAR_DIR/test/include")
            ;;
        app_dbg|blackbear-dbg)
            target_method="dbg"
            exe="$BLACKBEAR_DIR/blackbear-dbg"
            src_dirs=("$BLACKBEAR_DIR/src" "$BLACKBEAR_DIR/include" "$BLACKBEAR_DIR/test/src" "$BLACKBEAR_DIR/test/include")
            ;;
        app)
            blackbear_mac_target_status "app_${METHOD:-opt}"
            return $?
            ;;
        unit_opt|blackbear-unit-opt)
            target_method="opt"
            exe="$BLACKBEAR_DIR/unit/blackbear-unit-opt"
            src_dirs=("$BLACKBEAR_DIR/unit/src" "$BLACKBEAR_DIR/unit/include" "$BLACKBEAR_DIR/src" "$BLACKBEAR_DIR/include")
            ;;
        unit_dbg|blackbear-unit-dbg)
            target_method="dbg"
            exe="$BLACKBEAR_DIR/unit/blackbear-unit-dbg"
            src_dirs=("$BLACKBEAR_DIR/unit/src" "$BLACKBEAR_DIR/unit/include" "$BLACKBEAR_DIR/src" "$BLACKBEAR_DIR/include")
            ;;
        unit)
            blackbear_mac_target_status "unit_$(blackbear_mac_unit_method)"
            return $?
            ;;
        *)
            BLACKBEAR_TARGET_STATUS="UNKNOWN"
            echo "UNKNOWN"
            return 1
            ;;
    esac

    if blackbear_mac_neml_submodule_ok; then
        src_dirs+=("$BLACKBEAR_DIR/contrib/neml/src" "$BLACKBEAR_DIR/contrib/neml/include")
    fi

    BLACKBEAR_TARGET_EXE="$exe"

    if [[ ! -f "$exe" || ! -x "$exe" ]]; then
        BLACKBEAR_TARGET_STATUS="MISSING"
        echo "MISSING"
        return 0
    fi

    # Check Makefile / mk mtimes
    local mk
    for mk in "$BLACKBEAR_DIR/Makefile" "$BLACKBEAR_DIR/blackbear.mk" "$BLACKBEAR_DIR/contrib/neml.mk"; do
        if [[ -f "$mk" && "$mk" -nt "$exe" ]]; then
            BLACKBEAR_TARGET_STALE_REASON="${mk#"$BLACKBEAR_DIR"/} is newer than the binary"
            BLACKBEAR_TARGET_STATUS="STALE"
            echo "STALE"
            return 0
        fi
    done
    if [[ "$target" == unit* && "$BLACKBEAR_DIR/unit/Makefile" -nt "$exe" ]]; then
        BLACKBEAR_TARGET_STALE_REASON="unit/Makefile is newer than the binary"
        BLACKBEAR_TARGET_STATUS="STALE"
        echo "STALE"
        return 0
    fi

    # Check if MOOSE framework library was rebuilt more recently than the app binary
    if [[ -n "${MOOSE_DIR:-}" ]]; then
        local libmoose="$MOOSE_DIR/framework/libmoose-${target_method}.dylib"
        if [[ -f "$libmoose" && "$libmoose" -nt "$exe" ]]; then
            BLACKBEAR_TARGET_STALE_REASON="MOOSE library is newer than the binary (libmoose-${target_method}.dylib)"
            BLACKBEAR_TARGET_STATUS="STALE"
            echo "STALE"
            return 0
        fi
    fi

    # Check source file mtimes
    local existing_dirs=()
    local d
    for d in "${src_dirs[@]}"; do
        if [[ -d "$d" ]]; then
            existing_dirs+=("$d")
        fi
    done

    if [[ ${#existing_dirs[@]} -gt 0 ]]; then
        local newer_file
        local find_name_filter=( \( -name "*.C" -o -name "*.c" -o -name "*.cpp" -o -name "*.cc" -o -name "*.cxx" -o -name "*.h" -o -name "*.H" -o -name "*.hpp" -o -name "*.hh" \) )
        local exclude_generated=( ! -name "*Revision.h" )
        if [[ "$target" == unit* ]]; then
            newer_file="$(find "${existing_dirs[@]}" -type f "${find_name_filter[@]}" "${exclude_generated[@]}" ! -name "main.C" -newer "$exe" -print -quit 2>/dev/null || true)"
        else
            newer_file="$(find "${existing_dirs[@]}" -type f "${find_name_filter[@]}" "${exclude_generated[@]}" -newer "$exe" -print -quit 2>/dev/null || true)"
        fi
        if [[ -n "$newer_file" ]]; then
            BLACKBEAR_TARGET_STALE_REASON="Source changed since build: ${newer_file#"$BLACKBEAR_DIR"/}"
            BLACKBEAR_TARGET_STATUS="STALE"
            echo "STALE"
            return 0
        fi
    fi

    BLACKBEAR_TARGET_STATUS="BUILT"
    echo "BUILT"
    return 0
}

# Resolve an @rpath/<lib> reference against a binary's LC_RPATH entries.
blackbear_mac_resolve_rpath_lib()
{
    local exe="$1" leaf="$2" rpath
    while IFS= read -r rpath; do
        [[ -z "$rpath" ]] && continue
        rpath="${rpath/@loader_path/$(dirname "$exe")}"
        rpath="${rpath/@executable_path/$(dirname "$exe")}"
        if [[ -e "$rpath/$leaf" ]]; then
            echo "$rpath/$leaf"
            return 0
        fi
    done < <(otool -l "$exe" 2>/dev/null | awk '/LC_RPATH/{f=1} f&&/ path /{print $2; f=0}')
    return 1
}

# Describe which MOOSE/BlackBear/PETSc/NEML libraries a binary links, and flag any
# that no longer resolve on disk (stale module_loader or conda lib bumps).
# Sets BLACKBEAR_LINK_BROKEN=1 when at least one library cannot be found.
blackbear_mac_describe_links()
{
    local exe="$1"
    BLACKBEAR_LINK_BROKEN=0
    [[ -x "$exe" ]] || { echo "  (binary missing)"; return 0; }

    local line leaf resolved extra_missing=0
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        leaf="${line##*/}"
        local is_key=0
        [[ "$leaf" =~ ^lib(moose|module_loader|blackbear|hit|pcre|mesh|petsc|slepc|neml) ]] && is_key=1
        if [[ "$line" == @rpath/* ]]; then
            if resolved="$(blackbear_mac_resolve_rpath_lib "$exe" "$leaf")"; then
                [[ "$is_key" -eq 1 ]] && echo "  $leaf -> ${resolved/#$HOME/~}"
            else
                BLACKBEAR_LINK_BROKEN=1
                if [[ "$is_key" -eq 1 ]]; then
                    echo "  $leaf -> MISSING (no LC_RPATH entry has it)"
                else
                    extra_missing=$((extra_missing + 1))
                fi
            fi
        elif [[ "$line" != /usr/lib/* && "$line" != /System/* ]]; then
            if [[ -e "$line" ]]; then
                [[ "$is_key" -eq 1 ]] && echo "  $leaf -> ${line/#$HOME/~}"
            else
                BLACKBEAR_LINK_BROKEN=1
                if [[ "$is_key" -eq 1 ]]; then
                    echo "  $leaf -> MISSING (${line/#$HOME/~})"
                else
                    extra_missing=$((extra_missing + 1))
                fi
            fi
        fi
    done < <(otool -L "$exe" 2>/dev/null | tail -n +2 | awk '{print $1}')
    if [[ "$extra_missing" -gt 0 ]]; then
        echo "  ... and $extra_missing additional missing library reference(s)"
    fi
    return 0
}

# Serialize build/test/init/run per checkout. The first call re-execs the calling script
# under the lock; nested calls see the inherited lock descriptor and return immediately.
blackbear_mac_guard()
{
    local operation="$1"
    shift
    blackbear_mac_locate_repo
    if [[ "${BLACKBEAR_HARNESS_LOCK_ROOT:-}" == "$BLACKBEAR_DIR" &&
          -n "${BLACKBEAR_HARNESS_LOCK_FD:-}" && -e "/dev/fd/$BLACKBEAR_HARNESS_LOCK_FD" ]]; then
        return
    fi
    exec python3 "$SCRIPT_DIR/../harness/control.py" guard "$BLACKBEAR_DIR" "$operation" bash "$0" "$@"
}

blackbear_mac_shorten_paths()
{
    sed \
        -e "s|${BLACKBEAR_DIR}|<BLACKBEAR>|g" \
        -e "s|${MOOSE_DIR:-/nonexistent}|<MOOSE>|g" \
        -e "s|${CONDA_PREFIX:-/nonexistent}|<CONDA>|g"
}

# Print a short diagnosis when a log shows a dyld failure. Returns 0 if one was found.
blackbear_mac_diagnose_dyld_error()
{
    local log_file="$1"
    [[ -f "$log_file" ]] || return 1

    if grep -q "symbol not found in flat namespace" "$log_file" 2>/dev/null; then
        local mangled demangled=""
        mangled="$(grep "symbol not found in flat namespace" "$log_file" | head -n 1 |
            sed -E "s/.*symbol not found in flat namespace '([^']+)'.*/\1/")"
        if command -v c++filt >/dev/null 2>&1 && [[ -n "$mangled" ]]; then
            demangled="$(c++filt "$mangled" 2>/dev/null || true)"
        fi

        echo
        echo "============================================"
        echo " Dynamic Linker (dyld) ABI Error Detected"
        echo "============================================"
        echo "Missing symbol : ${demangled:-$mangled}"
        echo
        echo "Diagnosis:"
        echo "  BlackBear objects were compiled against different MOOSE headers than the"
        echo "  linked libmoose (MOOSE update or stale .d dependency files)."
        echo
        echo "Recommended action:"
        echo "  1. ./scripts/mac/blackbear.sh build <app|unit>"
        echo "  2. If it persists: 'make clean && make' in the BlackBear root"
        echo "============================================"
        echo
        return 0
    elif grep -q "Library not loaded" "$log_file" 2>/dev/null; then
        local lib method
        lib="$(grep "Library not loaded" "$log_file" | head -n 1 |
            sed -E "s/.*Library not loaded: ([^ ]+).*/\1/")"
        method="$(grep -Eo "lib(hit|pcre)-[a-z]+" "$log_file" | head -n 1 | sed -E 's/^lib(hit|pcre)-//')"
        method="${method:-${METHOD:-opt}}"

        echo
        echo "============================================"
        echo " Dynamic Linker (dyld) Missing Library"
        echo "============================================"
        echo "Missing library : $lib"
        echo
        echo "Diagnosis:"
        echo "  A linked shared library moved, changed version, or was rebuilt in MOOSE"
        echo "  (e.g. module_loader, libmoose, or PETSc/SLEPc bump in Conda)."
        echo
        echo "Recommended action:"
        echo "  1. ./scripts/mac/blackbear.sh build <app|unit>"
        echo "  2. If it persists with hit/pcre: in \$MOOSE_DIR/framework/contrib/{hit,pcre},"
        echo "     delete lib*-${method}*, *.${method}.lo, *.${method}.o and *.${method}.o.d, then rebuild"
        echo "============================================"
        echo
        return 0
    fi
    return 1
}

# Fail fast with a dyld diagnosis instead of letting every test fail on its own.
blackbear_mac_check_preflight()
{
    local exe="$1" probe="${2:---show-capabilities}"
    [[ -x "$exe" ]] || return 0

    local tmp_log
    tmp_log="$(mktemp /tmp/blackbear-preflight-XXXXXX.log)"
    if ! { "$exe" "$probe" >"$tmp_log" 2>&1; } 2>/dev/null; then
        if blackbear_mac_diagnose_dyld_error "$tmp_log"; then
            rm -f "$tmp_log"
            return 1
        fi
    fi
    rm -f "$tmp_log"
    return 0
}

# Run make with the full log written to a file and only a compact summary printed.
# BLACKBEAR_MAC_RAW=1 streams make output instead; BLACKBEAR_MAC_PROFILE=1 adds a build profile.
# Usage: blackbear_mac_make_target <label> <dir> <method> [<exe>]
blackbear_mac_make_target()
{
    local label="$1" dir="$2" method="$3" exe="${4:-}"
    local jobs="${BUILD_JOBS:-$JOBS}"

    if [[ "${BLACKBEAR_MAC_RAW:-0}" == "1" ]]; then
        blackbear_mac_section "Building $label ($method, raw mode)"
        echo "Directory: $dir"
        echo "MOOSE_DIR: ${MOOSE_DIR:-}"
        (cd "$dir" && make -j"$jobs" METHOD="$method")
        return $?
    fi

    local sha branch tree_state log_file
    sha="$(git -C "$BLACKBEAR_DIR" rev-parse --short=10 HEAD 2>/dev/null || echo "unknown")"
    branch="$(git -C "$BLACKBEAR_DIR" branch --show-current 2>/dev/null || true)"
    [[ -z "$branch" ]] && branch="detached-HEAD"
    if [[ -n "$(git -C "$BLACKBEAR_DIR" status --porcelain -uno 2>/dev/null)" ]]; then
        tree_state="DIRTY"
    else
        tree_state="clean"
    fi
    log_file="/tmp/blackbear-build-${label}-${sha}-$$.log"

    blackbear_mac_section "Building $label ($method)"
    echo "Directory : $dir"
    echo "MOOSE_DIR : ${MOOSE_DIR:-}"
    echo "Command   : make -j$jobs METHOD=$method"
    echo "Log file  : $log_file"

    local start_time elapsed status
    start_time="$(date +%s)"
    set +e
    (cd "$dir" && make -j"$jobs" METHOD="$method") >"$log_file" 2>&1
    status=$?
    set -e
    elapsed=$(( $(date +%s) - start_time ))

    if [[ $status -eq 0 ]]; then
        echo
        echo "========== BUILD SUMMARY =========="
        echo "RESULT    : BUILD SUCCESSFUL"
        echo "TARGET    : $label ($method)"
        echo "COMMIT    : $sha ($branch, $tree_state)"
        echo "TIME      : ${elapsed}s"
        [[ -n "$exe" && -x "$exe" ]] && echo "EXECUTABLE: $exe"
        echo "LOG       : $log_file"
        echo "==================================="

        if [[ "${BLACKBEAR_MAC_PROFILE:-0}" == "1" ]]; then
            echo
            echo "---------- BUILD PROFILE ----------"
            echo "WALL TIME         : ${elapsed}s"
            echo "C++ TUs COMPILED  : $(grep -cE 'Compiling C\+\+' "$log_file" 2>/dev/null || true)"
            echo "LINK STEPS        : $(grep -cE 'Linking (Library|Executable)' "$log_file" 2>/dev/null || true)"
            echo "PARALLEL JOBS     : $jobs"
            echo "-----------------------------------"
        fi
        return 0
    fi

    local error_regex='fatal error:|(^|[[:space:]])error:|undefined reference|Undefined symbols for architecture|linker command failed|ld: .*error|No rule to make target|No such file or directory|out of memory|Out of memory|Killed:|Segmentation fault|make(\[[0-9]+\])?: \*\*\*'
    local first_error_line="" reason failed_near="" key_errors context

    first_error_line="$(grep -nEi "$error_regex" "$log_file" 2>/dev/null | head -n 1 | cut -d: -f1 || true)"

    if [[ -n "$first_error_line" ]]; then
        reason="$(sed -n "${first_error_line}p" "$log_file" | blackbear_mac_shorten_paths | sed 's/^[[:space:]]*//' | cut -c1-500)"
        failed_near="$(sed -n "1,${first_error_line}p" "$log_file" |
            grep -E 'Compiling C\+\+|Linking (Library|Executable)' | tail -n 1 | blackbear_mac_shorten_paths || true)"
    else
        reason="make exited with code $status; no standard compiler/linker error pattern was detected."
    fi

    key_errors="$(grep -Ei "$error_regex" "$log_file" 2>/dev/null | blackbear_mac_shorten_paths | awk '
        length($0) <= 600 {
            if (!seen[$0]++) { print; count++ }
        }
        count >= 10 { exit }
    ' || true)"

    if [[ -n "$first_error_line" ]]; then
        local context_start=$((first_error_line - 4))
        (( context_start < 1 )) && context_start=1
        context="$(sed -n "${context_start},$((first_error_line + 10))p" "$log_file" | blackbear_mac_shorten_paths | awk '
            length($0) > 700 {
                if (!long_line) print "[long compiler command omitted]"
                long_line=1
                next
            }
            { long_line=0; print }
        ' || true)"
    else
        context="$(tail -n 15 "$log_file" | blackbear_mac_shorten_paths | awk '
            length($0) > 700 { print "[long compiler command omitted]"; next }
            { print }
        ' || true)"
    fi

    echo
    echo "========== BUILD SUMMARY =========="
    echo "RESULT    : BUILD FAILED"
    echo "TARGET    : $label ($method)"
    echo "COMMIT    : $sha ($branch, $tree_state)"
    echo "EXIT CODE : $status"
    echo "TIME      : ${elapsed}s"
    if [[ -n "$failed_near" ]]; then
        echo
        echo "FAILED NEAR:"
        echo "$failed_near"
    fi
    echo
    echo "REASON:"
    echo "$reason"
    if [[ -n "$key_errors" ]]; then
        echo
        echo "KEY ERRORS:"
        echo "$key_errors"
    fi
    echo
    echo "ERROR CONTEXT:"
    echo "-----------------------------------"
    echo "$context"
    echo "-----------------------------------"
    echo "FULL LOG  : $log_file"
    echo "==================================="

    return "$status"
}
