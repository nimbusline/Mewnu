# ADR-0013: Keep details, filters, and Help in the menu window

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

The menu window is the app's central workspace. Closing event details should return to the calendar without closing that window.

## Decision

ContentView switches its main area between calendar, filters, details, Help, and permission recovery. selectedEvent controls details, and clearing it closes them. Escape returns from Help or details, or exits filters. The header, footer, and resize handle remain in the window.

## Alternatives

- Show details in a separate popover or sheet: retains the overview beneath it, but introduces another dismissal and focus lifecycle inside MenuBarExtra. Content switching keeps return behavior in one route.
- Open dedicated windows for details and settings: supports simultaneous views, but adds window management and departure from menu-only operation.

## Consequences

One menu window provides a single navigation lifecycle and consistent return actions. Details, filters, and Help replace the overview, so users cannot view them side by side. Each new route must define its priority and Back/Escape behavior to keep transient state from obscuring the calendar.

## Implementation and validation

UI tests repeatedly open and close details and verify returning from Help and details with Escape while the menu window remains available.

Implementation references:

- [Mewnu/Views/ContentView.swift](../../Mewnu/Views/ContentView.swift)
- [Mewnu/Core/CalendarViewModel.swift](../../Mewnu/Core/CalendarViewModel.swift)
- [MewnuUITests/MewnuUITests.swift](../../MewnuUITests/MewnuUITests.swift)
