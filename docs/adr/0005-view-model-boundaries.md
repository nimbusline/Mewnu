# ADR-0005: Use one main-actor view model with injectable system boundaries

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

Permissions, selection, filters, and fetches must stay consistent. Tests must not require personal calendars or opening real system applications.

## Decision

CalendarViewModel is a main-actor ObservableObject responsible for application state. Inject CalendarService, CalendarWorkspace, UserDefaults, Calendar, and the clock closure. Keep presentation-only state such as Help and drag previews in ContentView.

## Alternatives

- Put logic directly in SwiftUI views: quicker setup, but harder to test in isolation.
- Add a global store or reducer framework: an explicit state machine, but adds abstractions and possible dependencies to a small app.

## Consequences

Injected boundaries allow deterministic state tests without opening system apps. One state owner makes transitions easier to follow, but concentrates coordination in CalendarViewModel. New features must preserve that ownership and avoid putting fetch or permission logic into views; main-actor state work still affects responsiveness.

## Implementation and validation

State changes and system actions are testable with injected services, workspace, defaults, calendar, and clock without using personal calendars or opening real apps.

Implementation references:

- [Mewnu/Core/CalendarViewModel.swift](../../Mewnu/Core/CalendarViewModel.swift)
- [Mewnu/Core/CalendarWorkspace.swift](../../Mewnu/Core/CalendarWorkspace.swift)
- [Mewnu/Core/Models.swift](../../Mewnu/Core/Models.swift)
- [MewnuTests/CalendarViewModelTests.swift](../../MewnuTests/CalendarViewModelTests.swift)
