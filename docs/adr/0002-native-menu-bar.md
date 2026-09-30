# ADR-0002: Use native SwiftUI without a Dock icon or main window

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

The app should provide a small additional view in the menu bar. Native controls and macOS integration take priority over cross-platform support.

## Decision

Use SwiftUI MenuBarExtra with the window style and AppKit for system integration. Enable LSUIElement to hide the app from the Dock. Ship only Apple frameworks, without third-party runtime libraries, and support macOS 26 or later.

## Alternatives

- Build the entire UI in AppKit: direct control of menu-window behavior, but more custom view and state-binding code than SwiftUI.
- Use Electron or a web view: reusable web UI, but additional runtime and native-integration work. Native macOS presentation and a small dependency surface favor SwiftUI.

## Consequences

Native controls and Apple frameworks keep the runtime dependency surface small. Platform support and window behavior depend on macOS APIs; a future cross-platform version would need a separate presentation layer. Menu-only operation also requires discoverable Help, recovery, and quit actions inside the menu.

## Implementation and validation

The app entry point creates a window-style MenuBarExtra, LSUIElement is enabled, and no external runtime library is required.

Implementation references:

- [Mewnu/MewnuApp.swift](../../Mewnu/MewnuApp.swift)
- [Mewnu/Info.plist](../../Mewnu/Info.plist)
- [project.yml](../../project.yml)
