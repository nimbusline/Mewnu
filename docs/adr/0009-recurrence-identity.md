# ADR-0009: Use EventKit occurrences and identify each occurrence separately

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

Occurrences of one series can share a framework identifier. SwiftUI still needs separate IDs, including for rescheduled occurrences.

## Decision

Use occurrences returned by EventKit for the grid range rather than implementing recurrence expansion. EventIdentity combines calendar ID, event ID, and start time, falling back to calendarItemIdentifier when eventIdentifier is absent. Length prefixes separate the identifier components unambiguously.

## Alternatives

- Implement a local recurrence engine: control over expansion, but duplicates exception and time-zone behavior supplied by EventKit.
- Derive IDs from series identity and an original occurrence date: could preserve selection when an exception moves, but requires reliable original-occurrence metadata for every returned event. Returned event identity and start time provide a uniform rule without that extra dependency.

## Consequences

Occurrence-specific IDs distinguish repeated events without a local recurrence engine. Including the start time means rescheduling an occurrence changes its ID; after refresh, details selected under the old ID close rather than following the moved occurrence. Recurrence exceptions and account synchronization remain dependent on EventKit behavior.

## Implementation and validation

Occurrences sharing a series identifier but starting at different times receive distinct IDs. Verify real recurrence exceptions using a test account.

Implementation references:

- [Mewnu/Core/CalendarService.swift](../../Mewnu/Core/CalendarService.swift)
- [MewnuTests/EventKitCalendarServiceTests.swift](../../MewnuTests/EventKitCalendarServiceTests.swift)
- [MewnuTests/CalendarMathTests.swift](../../MewnuTests/CalendarMathTests.swift)
