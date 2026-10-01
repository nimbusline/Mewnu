#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
source "$root/scripts/toolchain/xcodegen.env"
cd "$root"
generator="$root/build/tools/xcodegen-$MEWNU_XCODEGEN_VERSION/bin/xcodegen"
if [[ ! -x "$generator" ]]; then
  echo 'Run scripts/install-xcodegen.sh first.' >&2
  exit 1
fi
test "$("$generator" --version)" = "Version: $MEWNU_XCODEGEN_VERSION"
"$generator" generate
if [[ "${1:-}" == '--check' ]]; then
  python3 scripts/check-project-drift.py
elif [[ $# -ne 0 ]]; then
  echo 'Usage: scripts/generate-project.sh [--check]' >&2
  exit 2
fi
