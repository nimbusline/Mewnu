#!/bin/bash
# Re-sign nested updater helpers before their enclosing framework and app.
set -euo pipefail
if [[ $# -ne 2 ]]; then
  echo 'Usage: scripts/sign-app.sh APP SIGNING_IDENTITY' >&2
  exit 2
fi
root="$(cd "$(dirname "$0")/.." && pwd)"
app="$1"
identity="$2"
stage="$(mktemp -d "$root/build/Mewnu-entitlements.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
sign_options=(--timestamp)
if [[ "$identity" = - ]]; then sign_options=(--timestamp=none); fi
if [[ -n "${MEWNU_SIGN_KEYCHAIN:-}" ]]; then
  sign_options+=(--keychain "$MEWNU_SIGN_KEYCHAIN")
fi
# Sign nested Sparkle helpers from the inside out, preserving downloader entitlements.
sparkle="$app/Contents/Frameworks/Sparkle.framework"
for component in Versions/B/XPCServices/Installer.xpc Versions/B/XPCServices/Downloader.xpc Versions/B/Autoupdate Versions/B/Updater.app; do
  codesign "${sign_options[@]}" --force --options runtime --preserve-metadata=entitlements \
    --sign "$identity" "$sparkle/$component"
done
codesign "${sign_options[@]}" --force --options runtime --sign "$identity" "$sparkle"
# codesign does not expand Xcode build variables in a source entitlement plist.
release_entitlements="$stage/entitlements.plist"
python3 - "$root/Mewnu/Mewnu.entitlements" "$app/Contents/Info.plist" "$release_entitlements" <<'ENTITLEMENTS'
import plistlib, sys
from pathlib import Path
source = plistlib.loads(Path(sys.argv[1]).read_bytes())
bundle_id = plistlib.loads(Path(sys.argv[2]).read_bytes())["CFBundleIdentifier"]
key = "com.apple.security.temporary-exception.mach-lookup.global-name"
source[key] = [name.replace("$(PRODUCT_BUNDLE_IDENTIFIER)", bundle_id) for name in source[key]]
Path(sys.argv[3]).write_bytes(plistlib.dumps(source))
ENTITLEMENTS
codesign "${sign_options[@]}" --force --options runtime --entitlements "$release_entitlements" --sign "$identity" "$app"
codesign --verify --deep --strict --verbose=2 "$app"
