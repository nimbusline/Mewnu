# ADR-0038: Deliver signed automatic updates through Sparkle and GitHub Releases

- **Status:** accepted
- **Decision date:** 2026-10-01
- **Documented:** 2026-10-01
- **Implementation:** implemented; [local evidence and pending production checks](../UPDATER-VALIDATION.md).
- **Supersedes:** [ADR-0037](0037-manual-update-path.md)

## Context

The maintainer requested automatic update discovery and installation before the next release. Browser-only updates require repeated manual app replacement. An updater introduces executable downloads, signing keys, and a runtime dependency, which need explicit maintenance and release responsibilities.

## Decision

Embed Sparkle 2.10.0 through an exact Swift Package Manager dependency and commit its resolved revision. Use the fixed HTTPS GitHub Releases latest-download appcast URL; publish a signed appcast with each stable, signed, notarized DMG. Sparkle compares increasing bundle build numbers, verifies signed feeds and Ed25519 archive signatures before extraction, and installs/relaunches the app through its standard user interface and sandbox installer service.

Help provides a manual Check for updates action and separate automatic-check and automatic-install options. Both default to off; enabling installation requires checks, and disabling checks clears installation. Sparkle owns persistent preferences and scheduling (normally daily). Calendar refresh never triggers update checks. Retain the browser release link as a recovery path. Disable profiling and remote release-note rendering. Tests and synthetic previews inject a driver with no network or installation side effects.

Keep the main app sandboxed without a general network entitlement. Enable Sparkle's downloader/installer XPC services and only the two documented bundle-specific Mach lookup exceptions. Sign all embedded Sparkle tools inside out with the app's Developer ID before signing the enclosing app. The dedicated private Ed25519 key lives in the maintainer's login Keychain and GitHub's SPARKLE_EDDSA_PRIVATE_KEY secret; only its public key enters the repository. Release tooling must reject non-increasing build/marketing versions and failed signature/metadata checks. Serialize releases and mark a successful tagged stable release as latest.

This revises ADR-0001's local-only networking scope solely for software distribution and extends ADR-0023's release outputs. No account system, analytics, calendar uploads, or EventKit writes are introduced. GitHub receives ordinary update HTTP requests (including transport metadata such as IP address); no calendar content is included.

## Alternatives

- Poll the GitHub API and replace the app ourselves: duplicates a security-sensitive installer and version/signature logic.
- Keep browser-only updates: simpler but does not satisfy the requested automatic-update flow.

## Consequences

Sparkle becomes the first third-party runtime dependency. Its security updates, license, signing helpers, and compatibility require maintenance. The first updater-enabled version must be installed manually by existing 1.0.x users. Subsequent releases can update in-app. A feed is available only after its first release publishes; earlier checks can show a network/feed error. Offline checks preserve the installed app. Automatic installation can occur on quit and relaunch Mewnu, subject to Sparkle's standard authorization and user settings.

## Validation

Test driver defaults, manual-check gating, preference restoration, external changes, and disabling automatic installation. Test localized controls and Escape using the synthetic UI driver. Generate a signed synthetic feed/archive with an ephemeral key and reject tampering and non-increasing builds/versions. Run the unit coverage gate, UI suite, universal app/framework builds, and project drift safeguards.

Before declaring deployment verified, publish through the signed/notarized pipeline and test an actual old-to-new update on a separate account: offline/error behavior, tampered artifacts, consent, installation/relaunch, retained calendar filters/window height, keyboard and VoiceOver. Local builds and synthetic signature tests alone do not verify the production installer.

References: [Sparkle setup](https://sparkle-project.org/documentation/), [sandbox integration](https://sparkle-project.org/documentation/sandboxing/), [AppUpdater](../../Mewnu/Core/AppUpdater.swift), [release guide](../../RELEASING.md).
