#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
source "$root/scripts/toolchain/xcodegen.env"
install_dir="$root/build/tools/xcodegen-$MEWNU_XCODEGEN_VERSION"
task_tmp="$(mktemp -d)"
trap 'rm -rf "$task_tmp"' EXIT
curl --fail --location --retry 3 --proto '=https' --tlsv1.2 \
  "https://github.com/yonaskolb/XcodeGen/releases/download/$MEWNU_XCODEGEN_VERSION/xcodegen.zip" \
  -o "$task_tmp/xcodegen.zip"
(cd "$task_tmp" && echo "$MEWNU_XCODEGEN_SHA256  xcodegen.zip" | shasum -a 256 -c -)
unzip -q "$task_tmp/xcodegen.zip" -d "$task_tmp/extracted"
mkdir -p "$install_dir"
# The upstream archive contains xcodegen/bin/xcodegen.
cp -R "$task_tmp/extracted/xcodegen/bin" "$task_tmp/extracted/xcodegen/share" "$install_dir/"
chmod +x "$install_dir/bin/xcodegen"
test "$("$install_dir/bin/xcodegen" --version)" = "Version: $MEWNU_XCODEGEN_VERSION"
if [[ -n "${GITHUB_PATH:-}" ]]; then echo "$install_dir/bin" >> "$GITHUB_PATH"; fi
printf 'Installed XcodeGen %s in %s\n' "$MEWNU_XCODEGEN_VERSION" "$install_dir"
