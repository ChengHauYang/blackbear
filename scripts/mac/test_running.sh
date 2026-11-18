#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

exec "$SCRIPT_DIR/blackbear.sh" test all ${1+"$@"}
