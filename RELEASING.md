# Releasing Mewnu

## GitHub Actions (preferred)

`.github/workflows/release.yml` runs tests, imports the Developer ID certificate into a temporary keychain, signs Mewnu and its disk image, notarizes and staples the disk image, verifies Gatekeeper acceptance, and uploads the DMG and checksum. A manual workflow run creates a private Actions artifact. Pushing a matching `vX.Y.Z` tag publishes a GitHub Release only after the package job succeeds. The version in `project.yml` must match the tag.

The Mewnu repository needs these five **repository secrets**. They have the same names and values as the WhisperM release workflow, but GitHub does not copy secrets between repositories:

| Secret | Value |
| --- | --- |
| `APPLE_DEVELOPER_ID_P12_BASE64` | Base64 of the Developer ID certificate and private key `.p12` |
| `APPLE_DEVELOPER_ID_P12_PASSWORD` | Password protecting that `.p12` |
| `APPLE_ID` | Apple Account email for the Developer Team |
| `APPLE_TEAM_ID` | `492PXE825S` |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password for notarization |

Add them in **Repository Settings → Secrets and variables → Actions**. Use the GitHub form or `gh secret set` with its interactive hidden input; do not put secrets in shell command arguments, chat, or source files. The existing WhisperM app-specific password can be reused if it is still available, or a separate one can be created for Mewnu.

After configuring secrets, run **Actions → Signed macOS release → Run workflow** once and inspect the artifact. For a release, update `MARKETING_VERSION` in `project.yml`, merge to `main`, push a matching tag (for example `v1.0.0`), and let the workflow publish the assets.

Before packaging, run `scripts/install-xcodegen.sh`. CI and the local release script validate entitlement XML/plist syntax and regenerate with the pinned tool, rejecting project drift. Follow [the interaction checklist](docs/INTERACTION-VALIDATION.md), including actual dragging, VoiceOver, login on a test account, and manual app replacement. Record unperformed checks as unverified.

## Local alternative

Release from a Mac with Xcode 27+, XcodeGen 2.46.0 (pinned), a Developer ID Application certificate in the keychain, and an Apple Developer account configured for notarization. On the maintainer's Mac, Mewnu uses the same Developer ID certificate and Team ID as WhisperM by default.

To create a local notarytool profile, generate an app-specific password at [Apple Account](https://account.apple.com/) under **Sign-In and Security → App-Specific Passwords**. Then run this command with the Apple ID that belongs to Team `492PXE825S`:

```sh
xcrun notarytool store-credentials mewnu-release --apple-id 'YOUR_APPLE_ID' --team-id 492PXE825S
```

`notarytool` prompts securely for the app-specific password and validates the profile. Do not put the password in the command line or repository.

```sh
export MEWNU_NOTARY_PROFILE='mewnu-release'
scripts/release.sh 1.0.0
```

If no local notarytool profile exists, set `MEWNU_APPLE_ID` and `MEWNU_APP_PASSWORD` instead. Override `MEWNU_SIGN_IDENTITY` and `MEWNU_TEAM_ID` when releasing under a different Apple Developer team. Do not commit credentials or send them in chat.

Never commit these credentials. The script tests the project, builds a release app, signs it with hardened runtime, creates a signed disk image containing the app and an Applications shortcut, submits the DMG to Apple's notary service, and staples its ticket. It produces `dist/Mewnu-v1.0.0-macos.dmg` plus its checksum. Open the DMG on a separate Mac account, drag the app to Applications, and confirm Gatekeeper, calendar permission, and menu bar behavior.

When ready to publish, sign in with `gh auth login`, create the public repository `nimbusline/mewnu`, push the tested commit and tag `v1.0.0`, and attach the DMG and checksum to the GitHub release. Do not publish a release if any test or notarization step fails.
