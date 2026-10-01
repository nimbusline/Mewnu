#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
file="${1:-$root/Mewnu/Mewnu.entitlements}"
# No DTD loading or network access; strict XML syntax and plist structure are independent checks.
xmllint --nonet --noout "$file"
plutil -lint "$file"
