#!/bin/bash
set -euo pipefail

# Render the real SwiftUI views with synthetic data; never open an EventKit store.
project_root="$(cd "$(dirname "$0")/.." && pwd)"
output_dir="${1:-$project_root/docs/images}"
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"
stage="$(mktemp -d "${TMPDIR:-/tmp}/MewnuScreenshots.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
app="$stage/MewnuScreenshots.app"
resources="$app/Contents/Resources"
mkdir -p "$app/Contents/MacOS" "$resources"

cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>MewnuScreenshots</string>
<key>CFBundleIdentifier</key><string>io.github.nimbusline.mewnu.documentation</string>
<key>CFBundleName</key><string>MewnuScreenshots</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleDevelopmentRegion</key><string>en</string>
<key>LSUIElement</key><true/>
</dict></plist>
PLIST

documentation_version="$(sed -nE 's/^[[:space:]]*MARKETING_VERSION:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+)[[:space:]]*$/\1/p' "$project_root/project.yml")"
plutil -insert CFBundleShortVersionString -string "$documentation_version" "$app/Contents/Info.plist"

if ! xcrun actool "$project_root/Mewnu/Assets.xcassets" \
  --compile "$resources" --platform macosx --minimum-deployment-target 26.0 \
  --app-icon AppIcon --output-partial-info-plist "$stage/asset-info.plist" \
  > "$stage/assets.log"; then
  cat "$stage/assets.log" >&2
  exit 1
fi
cp -R "$project_root/Mewnu/en.lproj" "$resources/"

# This initializer only exists in the temporary documentation build. The view
# body and production sources are unchanged; the help state can be preset.
cp "$project_root/Mewnu/Views/ContentView.swift" "$stage/ContentView.swift"
cat >> "$stage/ContentView.swift" <<'SWIFT'

extension ContentView {
    init(documentationModel: CalendarViewModel, windowSize: MenuWindowSize, help: Bool) {
        self.model = documentationModel
        self.windowSize = windowSize
        self.preferences = AppPreferences(system: DemoAppPreferencesSystem())
        self._showingHelp = State(initialValue: help)
    }
}
SWIFT

xcrun swiftc -parse-as-library -swift-version 5 \
  "$project_root"/Mewnu/Core/*.swift \
  "$project_root/Mewnu/Views/MonthGridView.swift" "$stage/ContentView.swift" \
  "$project_root/scripts/documentation-screenshots.swift" \
  -o "$app/Contents/MacOS/MewnuScreenshots"
"$app/Contents/MacOS/MewnuScreenshots" "$output_dir" \
  -AppleLanguages '(en)' -AppleLocale en_GB
printf 'Screenshots saved to %s\n' "$output_dir"
