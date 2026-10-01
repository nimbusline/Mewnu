# Releasing Mewnu

## GitHub Actions (preferred)

`.github/workflows/release.yml` runs tests, imports the Developer ID certificate into a temporary keychain, signs Mewnu and its disk image, notarizes and staples the disk image, verifies Gatekeeper acceptance, and uploads the DMG, checksum, and signed Sparkle appcast. A manual workflow run creates a private Actions artifact. Pushing a matching `vX.Y.Z` tag publishes a GitHub Release only after the package job succeeds. The version in `project.yml` must match the tag.

The Mewnu repository needs these six **repository secrets**. They have the same names and values as the WhisperM release workflow, but GitHub does not copy secrets between repositories:

| Secret | Value |
| --- | --- |
| `SPARKLE_EDDSA_PRIVATE_KEY` | Sparkle Ed25519 private seed exported from the dedicated `io.github.nimbusline.mewnu` Keychain account; never print it |
| `APPLE_DEVELOPER_ID_P12_BASE64` | Base64 of the Developer ID certificate and private key `.p12` |
| `APPLE_DEVELOPER_ID_P12_PASSWORD` | Password protecting that `.p12` |
| `APPLE_ID` | Apple Account email for the Developer Team |
| `APPLE_TEAM_ID` | `492PXE825S` |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password for notarization |

Add them in **Repository Settings → Secrets and variables → Actions**. Use the GitHub form or `gh secret set` with its interactive hidden input; do not put secrets in shell command arguments, chat, or source files. The existing WhisperM app-specific password can be reused if it is still available, or a separate one can be created for Mewnu.

After configuring secrets, run **Actions → Signed macOS release → Run workflow** once and inspect the artifact. For a release, increase both `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml`, merge to `main`, push a matching tag (for example `v1.0.0`), and let the workflow publish the assets.

Before packaging, run `scripts/install-xcodegen.sh` and `scripts/install-sparkle-tools.sh`. CI and the local release script validate entitlement XML/plist syntax and regenerate with the pinned tool, rejecting project drift. Follow [the interaction checklist](docs/INTERACTION-VALIDATION.md), including actual dragging, VoiceOver, login on a test account, and manual app replacement. Record unperformed checks as unverified.

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

Never commit these credentials. The script tests the project, builds a release app, signs it with hardened runtime, creates a signed disk image containing the app and an Applications shortcut, submits the DMG to Apple's notary service, and staples its ticket. It produces `dist/Mewnu.dmg` plus `dist/Mewnu.dmg.sha256`. Open the DMG on a separate Mac account, drag the app to Applications, and confirm Gatekeeper, calendar permission, and menu bar behavior.

Prefer the tagged GitHub workflow for publication. For a local release, authenticate with `gh auth login`, push the tested commit and matching version tag, and publish the verified DMG, checksum, and signed appcast together; avoid running local and workflow publication for the same tag. Do not publish a release if any test or notarization step fails.

## Automatic updater release contract

Sparkle 2.10.0 and its exact package revision are pinned. The signed appcast is served from `https://github.com/nimbusline/Mewnu/releases/latest/download/appcast.xml`; each enclosure uses the immutable matching tag's DMG URL. Every release publishes `Mewnu.dmg` and `Mewnu.dmg.sha256` with these fixed filenames. The README download uses `https://github.com/nimbusline/Mewnu/releases/latest/download/Mewnu.dmg`; updater enclosures retain the versioned tag URL so each signed feed points to its matching package. Only stable tagged releases publish the feed. Manual workflow runs retain it in private artifacts. The release workflow serializes publication and marks the successful stable tag as latest. Never edit signed XML after generation.

The dedicated Ed25519 account is `io.github.nimbusline.mewnu` in the maintainer's login Keychain. Its public key is in Info.plist; its private seed is configured as `SPARKLE_EDDSA_PRIVATE_KEY` in GitHub Actions. Local feed generation uses the Keychain account; CI passes the secret through stdin. Back up the key securely and follow Sparkle's key-rotation procedure if it is lost. Never paste/export its value into chat, logs, arguments, or tracked files.

`release.sh` checks increasing versions/builds, signs embedded Sparkle XPC services and helpers before the framework/app, notarizes and staples the DMG, then generates and verifies signed feed metadata. The next updater-enabled release requires one manual installation for users of 1.0.x. Before declaring automatic installation verified, test a genuine older/newer signed and notarized pair on a separate account, including offline/error paths, rejected tampering, preference retention, relaunch, keyboard, and VoiceOver. First-release checks will fail while no public appcast exists.
