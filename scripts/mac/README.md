# BlackBear macOS Build & Test Harness

A single state-aware CLI for building, testing, and diagnosing BlackBear on Apple Silicon macOS.

## Quick Start

```bash
# Read-only living map & diagnostics
./scripts/mac/blackbear.sh dummy
./scripts/mac/blackbear.sh doctor

# Configure MOOSE if conf_vars.mk is missing
./scripts/mac/blackbear.sh init

# Incremental build (quiet: full log in /tmp, compact summary on screen)
./scripts/mac/blackbear.sh build app       # or: unit, all (compile is an alias)
./scripts/mac/blackbear.sh build app -j 8 --profile

# Fast test run without rebuilding (fails if binaries are missing or stale)
./scripts/mac/blackbear.sh test app        # or: unit, all
./scripts/mac/blackbear.sh test actions    # bare pattern = app tests, run_tests --re
./scripts/mac/blackbear.sh test app --failed
./scripts/mac/blackbear.sh test unit MySampleTests*   # gtest filter

# Build and verify
./scripts/mac/blackbear.sh verify app      # or: unit, all
./scripts/mac/blackbear.sh verify app concrete_ASR

# Run a single input file
./scripts/mac/blackbear.sh run test/tests/actions/test_actions.i

# Full end-to-end pipeline (init -> build all -> test all)
./scripts/mac/blackbear.sh all

# Output & formatting helpers
./scripts/mac/blackbear.sh format --check
./scripts/mac/blackbear.sh logstat <log...> [--verbose]
./scripts/mac/blackbear.sh compare <a> <b> [--cmp SPEC]
./scripts/mac/blackbear.sh exodiff <a.e> <b.e>
./scripts/mac/blackbear.sh help --agent
```

`./scripts/blackbear.sh` is also available as a convenience wrapper to `./scripts/mac/blackbear.sh`.

## MOOSE Resolution

Matches BlackBear's `Makefile` and `run_tests`:
1. `BLACKBEAR_MOOSE_DIR` (if explicitly set)
2. `./moose` submodule (if `moose/framework/Makefile` exists)
3. `../moose` sibling checkout (if `../moose/framework/Makefile` exists)

`contrib/neml` is optional; BlackBear builds normally with or without it.

## Token-saving & Guard Behavior

- **Quiet build.** Full `make` logs go to `/tmp/blackbear-build-<label>-<sha>-<pid>.log`. Success prints a
  short `BUILD SUMMARY`. Failure prints the failing step, reason, up to 10 deduplicated key errors, and short
  error context with paths shortened to `<BLACKBEAR>` / `<MOOSE>` / `<CONDA>`. Use `--raw` to stream `make`
  output and `--profile` for TU/link counts.
- **Test summary.** Test runs end with `RESULT scope=... passed= failed= skipped= status= exit= process_exit= reason=`.
  Zero selected tests or a missing summary is an `ERROR`, not a pass.
- **Preflight.** Before app/unit tests or `run`, `--show-capabilities` / `--gtest_list_tests` runs to catch
  stale `dyld` linkage (e.g. after MOOSE or Conda updates) before running the full suite.
- **Checkout lock.** `init`, `build`, `compile`, `test`, `verify`, `all`, `run`, and `format` take a per-checkout
  lock (`.git/blackbear-harness.lock`), failing fast with `checkout busy` if another run is active.

## Environment Overrides

- `METHOD`: `opt` (default) or `dbg`
- `UNIT_METHOD`: Method for unit binary (default: `METHOD`)
- `JOBS`: Parallel test processes (default: `8` via `scripts/mac/harness.conf`)
- `BUILD_JOBS`: Parallel compile jobs (default: `JOBS`)
- `BLACKBEAR_MOOSE_DIR`: Explicit MOOSE checkout path override
- `BLACKBEAR_CONDA_ENV`: Conda environment name (default: `moose`)
