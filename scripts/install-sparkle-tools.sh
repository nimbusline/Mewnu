#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
source "$root/scripts/toolchain/sparkle.env"
install_dir="$root/build/tools/sparkle-$MEWNU_SPARKLE_VERSION"
task_tmp="$(mktemp -d)"
trap 'rm -rf "$task_tmp"' EXIT
curl --fail --location --retry 5 --retry-all-errors --retry-delay 2 --proto '=https' --tlsv1.2 \
  "https://github.com/sparkle-project/Sparkle/releases/download/$MEWNU_SPARKLE_VERSION/Sparkle-$MEWNU_SPARKLE_VERSION.tar.xz" \
  -o "$task_tmp/sparkle.tar.xz"
(cd "$task_tmp" && echo "$MEWNU_SPARKLE_SHA256  sparkle.tar.xz" | shasum -a 256 -c -)
mkdir -p "$install_dir"
tar -xf "$task_tmp/sparkle.tar.xz" -C "$install_dir"
printf 'Installed Sparkle tools %s in %s\n' "$MEWNU_SPARKLE_VERSION" "$install_dir"
