#!/bin/bash
# Use only on trusted refs. Do not enable shell tracing.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "$#" -ne 1 ] || [[ ! "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo 'Usage: scripts/ci-signed-release.sh VERSION' >&2
  exit 2
fi
for name in SPARKLE_EDDSA_PRIVATE_KEY APPLE_DEVELOPER_ID_P12_BASE64 APPLE_DEVELOPER_ID_P12_PASSWORD APPLE_ID APPLE_TEAM_ID APPLE_APP_SPECIFIC_PASSWORD; do
  if [ -z "${!name:-}" ]; then
    echo "Missing release secret: $name" >&2
    exit 2
  fi
done

umask 077
signing_dir="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/mewnu-signing.XXXXXX")"
keychain="$signing_dir/signing.keychain-db"
security list-keychains -d user > "$signing_dir/previous-keychains.txt"
cleanup() {
  python3 - "$signing_dir/previous-keychains.txt" <<'RESTORE' || true
import shlex, subprocess, sys
from pathlib import Path
subprocess.run(['security', 'list-keychains', '-d', 'user', '-s', *shlex.split(Path(sys.argv[1]).read_text())], check=True)
RESTORE
  security delete-keychain "$keychain" >/dev/null 2>&1 || true
  rm -rf "$signing_dir"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

keychain_password="$(openssl rand -hex 32)"
printf '%s' "$APPLE_DEVELOPER_ID_P12_BASE64" | base64 --decode > "$signing_dir/certificate.p12"
security create-keychain -p "$keychain_password" "$keychain"
security set-keychain-settings -lut 7200 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"
python3 - "$signing_dir/previous-keychains.txt" "$keychain" <<'SEARCH'
import shlex, subprocess, sys
from pathlib import Path
subprocess.run(['security', 'list-keychains', '-d', 'user', '-s', sys.argv[2], *shlex.split(Path(sys.argv[1]).read_text())], check=True)
SEARCH
security import "$signing_dir/certificate.p12" -k "$keychain" -P "$APPLE_DEVELOPER_ID_P12_PASSWORD" -T /usr/bin/codesign >/dev/null
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$keychain_password" "$keychain" >/dev/null
rm "$signing_dir/certificate.p12"

security find-identity -v -p codesigning "$keychain" > "$signing_dir/identities.txt"
sign_identity="$(python3 - "$signing_dir/identities.txt" <<'IDENTITY'
import os, re, sys
from pathlib import Path
pattern = r'([0-9A-Fa-f]{40}) "Developer ID Application: [^"\n]+ \(' + re.escape(os.environ['APPLE_TEAM_ID']) + r'\)"'
matches = re.findall(pattern, Path(sys.argv[1]).read_text())
if len(matches) != 1:
    sys.exit('Expected exactly one Developer ID Application identity for APPLE_TEAM_ID.')
print(matches[0])
IDENTITY
)"
[ -n "$sign_identity" ] || exit 1

profile=mewnu-ci-release
xcrun notarytool store-credentials "$profile" --keychain "$keychain" \
  --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_SPECIFIC_PASSWORD" >/dev/null
unset APPLE_DEVELOPER_ID_P12_BASE64 APPLE_DEVELOPER_ID_P12_PASSWORD APPLE_APP_SPECIFIC_PASSWORD
umask 022
MEWNU_SIGN_IDENTITY="$sign_identity" \
MEWNU_TEAM_ID="$APPLE_TEAM_ID" \
MEWNU_SIGN_KEYCHAIN="$keychain" \
MEWNU_NOTARY_PROFILE="$profile" \
MEWNU_NOTARY_KEYCHAIN="$keychain" \
  scripts/release.sh "$1"

app="$PWD/build/DerivedData/Build/Products/Release/Mewnu.app"
artifact="$PWD/dist/Mewnu-v$1-macos.dmg"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")" = "$1"
test "$(/usr/libexec/PlistBuddy -c 'Print :LSUIElement' "$app/Contents/Info.plist")" = true
codesign --verify --deep --strict "$app"
codesign --verify --verbose=2 "$artifact"
xcrun stapler validate "$artifact"
hdiutil verify "$artifact"
spctl --assess --type open --context context:primary-signature --verbose=2 "$artifact"
(cd dist && shasum -a 256 -c "Mewnu-v$1-macos.dmg.sha256")
test -s "$artifact"
