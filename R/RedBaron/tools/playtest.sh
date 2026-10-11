#!/usr/bin/env bash
# D5 player candidate: real speed, sound, physical keyboard, no VERIFY fixtures.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
. "$ROOT/tmp/dev/amiga/env.sh"
cd "$ROOT/tmp/dev"
exec python3 -B "$ROOT/R/RedBaron/tools/playtest.py" "$@"
