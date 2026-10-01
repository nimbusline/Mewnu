#!/bin/zsh
set -euo pipefail

if [[ $# -ne 1 || ! "$1" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
  print -u2 'Usage: scripts/release.sh VERSION (for example 1.0.0)'
  exit 2
fi

sign_identity="${MEWNU_SIGN_IDENTITY:-Developer ID Application: Michael Gerdemann (492PXE825S)}"
team_id="${MEWNU_TEAM_ID:-492PXE825S}"
if ! security find-identity -v -p codesigning | grep -Fq -- "$sign_identity"; then
  print -u2 "Developer ID certificate not found: $sign_identity"
  exit 2
fi
if [[ -n ${MEWNU_NOTARY_PROFILE:-} ]]; then
  notary_options=(--keychain-profile "$MEWNU_NOTARY_PROFILE")
  if [[ -n ${MEWNU_NOTARY_KEYCHAIN:-} ]]; then
    notary_options+=(--keychain "$MEWNU_NOTARY_KEYCHAIN")
  fi
else
  for name in MEWNU_APPLE_ID MEWNU_APP_PASSWORD; do
    if [[ -z ${(P)name:-} ]]; then
      print -u2 "Set MEWNU_NOTARY_PROFILE or $name for notarization"
      exit 2
    fi
  done
  notary_options=(--apple-id "$MEWNU_APPLE_ID" --team-id "$team_id" --password "$MEWNU_APP_PASSWORD")
fi

version=$1
root=${0:A:h:h}
cd "$root"
python3 scripts/check-update-version.py "$version"
scripts/validate-entitlements.sh
scripts/generate-project.sh --check
xcodebuild -project Mewnu.xcodeproj -scheme Mewnu -destination 'platform=macOS' CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES test
xcodebuild -project Mewnu.xcodeproj -scheme Mewnu -configuration Release -destination 'platform=macOS' -derivedDataPath "$root/build/DerivedData" CODE_SIGNING_ALLOWED=NO MARKETING_VERSION="$version" ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO build

app="$root/build/DerivedData/Build/Products/Release/Mewnu.app"
binary="$app/Contents/MacOS/Mewnu"
lipo -verify_arch arm64 "$binary"
lipo -verify_arch x86_64 "$binary"
print "Release architectures: $(lipo -archs "$binary")"
sign_options=()
if [[ -n ${MEWNU_SIGN_KEYCHAIN:-} ]]; then
  sign_options=(--keychain "$MEWNU_SIGN_KEYCHAIN")
fi
scripts/sign-app.sh "$app" "$sign_identity"
codesign --verify --deep --strict --verbose=2 "$app"

mkdir -p "$root/dist"
staging="$(mktemp -d "$root/build/Mewnu-dmg.XXXXXX")"
trap 'rm -rf -- "$staging"' EXIT
ditto "$app" "$staging/Mewnu.app"
ln -s /Applications "$staging/Applications"

artifact="$root/dist/Mewnu.dmg"
hdiutil create -volname Mewnu -srcfolder "$staging" -format UDZO -ov "$artifact"
codesign "${sign_options[@]}" --force --timestamp --identifier io.github.nimbusline.mewnu.dmg --sign "$sign_identity" "$artifact"
codesign --verify --verbose=2 "$artifact"
xcrun notarytool submit "$artifact" "${notary_options[@]}" --wait
xcrun stapler staple "$artifact"
xcrun stapler validate "$artifact"
codesign --verify --verbose=2 "$artifact"
hdiutil verify "$artifact"
spctl --assess --type open --context context:primary-signature --verbose=2 "$artifact"
(cd "$root/dist" && shasum -a 256 "Mewnu.dmg" > "Mewnu.dmg.sha256")
scripts/generate-update-feed.sh "$version" "$artifact" "$app"
print "Release ready: $artifact"
