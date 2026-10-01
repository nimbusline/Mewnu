# ADR-0036: Offer an optional launch-at-login setting

- **Status:** accepted
- **Decision date:** 2026-10-01
- **Documented:** 2026-10-01
- **Implementation:** implemented; automated evidence and remaining manual checks are recorded in [implementation validation](../ADR-IMPLEMENTATION-VALIDATION.md).

## Context

A menu bar calendar is useful immediately after login. At review time, Mewnu offered no in-app autostart setting. This is a convenience feature requiring a product decision, rather than a correction to event-reading behavior. It extends the preferences described in [ADR-0011](0011-local-preferences.md).

## Decision

Offer a localized, accessible Launch at login preference in the existing menu window, disabled by default. Use the native ServiceManagement main-app login-item mechanism and display the system's actual registration/approval state. Enabling or disabling is an explicit user action; failures and required system approval remain visible and recoverable. Keep menu bar presentation and read-only EventKit access.

## Alternatives

- **Document manual setup in System Settings only.** Adds no app integration, but makes routine setup harder to discover.
- **Enable automatically on first launch.** Reduces setup, but starts an app at login without the user choosing it.

## Consequences

Users can choose persistent availability. System-managed registration introduces approval, failure, and externally changed states that must be reflected correctly. A saved Boolean alone cannot establish whether autostart is enabled.

## Implementation and validation

Use the supported native API; verify actual signed/sandboxed registration on a test account before release. Isolate registration behind an injectable boundary and test disabled, enabled, approval-required, and failure states without changing the developer's login items in unit tests. On a test account, verify enable/disable, actual login launch, relaunch, and external changes in System Settings. Check English/German labels, keyboard activation, and VoiceOver status announcements.

References: [App entry point](../../Mewnu/MewnuApp.swift), [ContentView](../../Mewnu/Views/ContentView.swift), [project.yml](../../project.yml), [Entitlements](../../Mewnu/Mewnu.entitlements), [ADR-0001](0001-product-scope.md), [ADR-0016](0016-localization-accessibility.md).
