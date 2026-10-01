# Automatic updater validation — 2026-10-01

This record covers ADR-0038 and the successor to the browser-only updater. The first public updater-enabled release has not been published by this implementation task.

## Local automated evidence

- Xcode 27.0, macOS 26.6.2; XcodeGen 2.46.0; Sparkle framework and signing tools 2.10.0, exact package revision committed and tool archive checksum verified.
- 57 unit tests passed, including explicit check gating, disabled defaults, restoration of driver preferences, external changes, and automatic-install/check dependencies.
- Required core-file coverage: CalendarMath 100%, CalendarText 100%, CalendarViewModel 100%, CalendarService 97.7%, EventDisplayText 97.5%.
- Full UI suite: 13 tests, 12 passed, one opt-in real-pointer test skipped, zero failures. Synthetic German controls confirm enabled/disabled installation, native numeric checkbox states, explicit update action, and Escape navigation. No update downloads or installations occur in these tests.
- Universal Release app and Sparkle framework contain arm64 and x86_64 slices. The signing helper passes ad-hoc nested signature verification, preserves calendar/sandbox rights, expands the two installer Mach names, and adds no general network entitlement. This is not Developer ID/notarization evidence.
- The actual feed-generation shell script passes a synthetic archive test with an ephemeral signing key. Feed/archive signature verification succeeds; modified archives/feeds, wrong metadata URLs/versions, and non-increasing versions/builds are rejected.
- Entitlement XML/plist checks, project-generation drift safeguards, synchronized EN/DE keys, shell syntax, and whitespace checks passed. Synthetic documentation screenshot regenerated and inspected. Both automatic options and profiling are off by default; feed and archive verification are required.

Local logs/results live under ignored `build/updater-validation/`. Some test launches from the external workspace volume stalled in dyld before application code ran. The definitive UI run used `CONFIGURATION_BUILD_DIR=/tmp/MewnuUpdaterValidationProducts/Debug`, while derived data and results stayed on the workspace volume. No build-setting workaround was committed. An initial checkbox test used a string cast; XCTest exposes macOS checkbox values as NSNumber, and the corrected test passes.

## Release and manual checks still required

Publish only after the updated GitHub CI and signed/notarized release workflow pass. The dedicated private Ed25519 key is in the maintainer's login Keychain and GitHub Actions secret; only its public key is tracked. A production appcast is unavailable until the first tagged updater release publishes its assets.

Use a separate account and a genuine older/newer Developer ID signed and notarized pair to verify the installer service, signature rejection, offline/error recovery, automatic preferences, replacement, relaunch, retained calendar filters/window height, complete keyboard focus, and VoiceOver in both languages. Ad-hoc signatures and synthetic driver tests do not establish these production results. Existing 1.0.x apps require a one-time manual installation of the first updater-enabled release.
