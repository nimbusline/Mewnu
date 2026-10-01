#!/bin/bash
# Never enable tracing: the signing secret is passed only through stdin.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
source "$root/scripts/toolchain/sparkle.env"
tools="$root/build/tools/sparkle-$MEWNU_SPARKLE_VERSION/bin"
if [[ $# -ne 3 || ! "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo 'Usage: scripts/generate-update-feed.sh VERSION ARCHIVE APP' >&2
  exit 2
fi
version="$1"
artifact="$2"
app="$3"
stage="$(mktemp -d "$root/build/Mewnu-feed.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
cp "$artifact" "$stage/"
run_tool() {
  local tool="$1"
  shift
  if [[ -n "${SPARKLE_EDDSA_PRIVATE_KEY:-}" ]]; then
    printf '%s' "$SPARKLE_EDDSA_PRIVATE_KEY" | "$tools/$tool" --ed-key-file - "$@"
  else
    "$tools/$tool" --account io.github.nimbusline.mewnu "$@"
  fi
}
run_tool generate_appcast --maximum-deltas 0 --maximum-versions 1 \
  --download-url-prefix "https://github.com/nimbusline/Mewnu/releases/download/v$version/" \
  --link "https://github.com/nimbusline/Mewnu/releases/tag/v$version" "$stage"
run_tool sign_update --verify "$stage/appcast.xml"
python3 "$root/scripts/validate-update-feed.py" "$stage/appcast.xml" "$artifact" "$version" "$app/Contents/Info.plist"
cp "$stage/appcast.xml" "$(dirname "$artifact")/appcast.xml"
