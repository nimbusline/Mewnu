# ADR-0023: Distribute a signed and notarized DMG with an Applications shortcut

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

A single macOS app needs a familiar drag-to-Applications installation flow.

## Decision

Package Mewnu.app and an Applications symlink in a compressed DMG with a SHA-256 file. Sign the app and DMG with Developer ID; use Hardened Runtime and calendar entitlements for the app. Notarize and staple the DMG, then verify it with codesign, stapler, hdiutil, and Gatekeeper. Publish only after a matching vX.Y.Z tag passes the package job. Manual runs create an artifact.

## Alternatives

- Distribute a ZIP: simple, but lacks the drag-to-Applications flow.
- Use a PKG installer: a formal assistant, but adds unnecessary installation machinery for one app.

## Consequences

The DMG provides a familiar installation flow and a verifiable distribution artifact. Releases depend on signing credentials, certificate renewal, and Apple's notarization service, adding steps and possible failures beyond compilation. A matching version tag and successful package checks are required before publication.

## Implementation and validation

The DMG contains the app and Applications shortcut and passes signature, notarization, stapling, Gatekeeper, and checksum checks. The tag matches the project version.

Implementation references:

- [scripts/release.sh](../../scripts/release.sh)
- [scripts/ci-signed-release.sh](../../scripts/ci-signed-release.sh)
- [.github/workflows/release.yml](../../.github/workflows/release.yml)
- [RELEASING.md](../../RELEASING.md)

## Extension on 2026-10-01

[ADR-0038](0038-signed-automatic-updates.md) adds automatic updates. Stable releases now also publish a signed Sparkle appcast; embedded helpers are signed inside out and build numbers increase.
