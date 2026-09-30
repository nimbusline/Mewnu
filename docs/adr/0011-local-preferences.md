# ADR-0011: Save hidden calendar IDs and window height in UserDefaults

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

Filters should survive restarts without storing event content or confusing calendars when names change.

## Decision

Store hiddenCalendarIDs as a sorted list and menuWindowHeight as a number in UserDefaults. Filter by stable calendar IDs; previously unknown IDs are visible by default. Rebuild daily indexes from the existing snapshot after filter changes without fetching EventKit again.

## Alternatives

- Save visible calendar IDs as an allowlist: explicitly preserves included calendars, but hides newly discovered calendars until users enable them. Hidden IDs fit the default of showing new calendars.
- Store preferences in a dedicated configuration file: enables an explicit portable schema, but adds file handling and migration work for two local settings. UserDefaults fits the small preference set.

## Consequences

ID-based preferences survive title changes and avoid storing event content. New calendar IDs are visible by default; a recreated account may receive new IDs and lose its previous hidden selection. Saved hidden IDs can outlive their calendars, and UserDefaults provides local preferences rather than cross-device synchronization.

## Implementation and validation

Recreating models with the same defaults retains filters and height. New calendars are visible, and filter changes need no extra store query.

Implementation references:

- [Mewnu/Core/CalendarViewModel.swift](../../Mewnu/Core/CalendarViewModel.swift)
- [Mewnu/Core/MenuWindowSize.swift](../../Mewnu/Core/MenuWindowSize.swift)
- [MewnuTests/CalendarViewModelTests.swift](../../MewnuTests/CalendarViewModelTests.swift)
- [MewnuTests/MenuWindowSizeTests.swift](../../MewnuTests/MenuWindowSizeTests.swift)
