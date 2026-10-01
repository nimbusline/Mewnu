# ADR-0037: Offer a browser-based path to release updates

- **Status:** accepted
- **Decision date:** 2026-10-01
- **Documented:** 2026-10-01
- **Implementation:** implemented; automated evidence and remaining manual checks are recorded in [implementation validation](../ADR-IMPLEMENTATION-VALIDATION.md).

## Context

At review time, README linked to signed DMG releases, but the app had no direct path to updates. An embedded updater would add networking, dependency, and installation responsibilities beyond Mewnu's current local product contract. Update convenience is a product enhancement, not an event-reading defect.

## Decision

Show the installed version and a localized Open latest release action in Help. On explicit activation, open the fixed project's GitHub Releases page in the default browser; the user compares versions and downloads/installs the signed DMG. Do not label the action Check for updates because the app does not perform a version comparison.

Keep release discovery manual: no background network polling, app-side downloads, automatic installation, or new updater dependency. Any later automatic updater requires its own ADR revisiting [ADR-0001](0001-product-scope.md) and [ADR-0023](0023-signed-dmg-release.md).

## Alternatives

- **Keep only the README release link.** No UI work, but users must leave the app and find the project documentation.
- **Embed an automatic updater.** Easier discovery and installation, but introduces networking, update authenticity checks, dependency maintenance, and a changed product contract.

## Consequences

Users get a discoverable route to releases while the app remains free of an update service. Version comparison and replacement remain manual; the app cannot claim that it is up to date. Browser launch failure needs a readable recovery message.

## Implementation and validation

Test installed-version display, the exact project release URL, explicit activation, and browser-open failure through an injectable boundary. Confirm startup and calendar refresh do not trigger release requests. Check English/German labels, keyboard and VoiceOver use, and document the manual replacement steps. Verify replacement with a signed release on a test account, including retained calendar filters and window height.

References: [ContentView](../../Mewnu/Views/ContentView.swift), [workspace boundary](../../Mewnu/Core/CalendarWorkspace.swift), [Info.plist](../../Mewnu/Info.plist), [README](../../README.md), [release guide](../../RELEASING.md).
