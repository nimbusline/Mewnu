# ADR-0007: Retain same-month data on fetch failure and clear it on lost access

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

Temporary fetch failures differ from revoked permission. Events from an older month must not appear as current data.

## Decision

Retain the last snapshot and event selection for the same month on a transient failure, and set errorMessage. Clear events and day indexes before fetching a different month. When refresh detects missing access, clear calendars, events, indexes, selected event, and error. After a successful fetch, update or remove the detail selection by event ID.

## Alternatives

- Clear everything on any error: a clear failure state, but loses useful data during brief interruptions.
- Always retain the last snapshot: continuous display, but risks wrong-month data and unauthorized display after detected revocation.

## Consequences

Same-month data remains useful during transient failures, but may be stale until a successful refresh; the error indicates that state. Changing months removes old events immediately, so a failed new-month fetch leaves an empty agenda. Data is cleared after permission loss is detected, which depends on a refresh checking authorization.

## Implementation and validation

Test same-month retention, empty event data after month changes, clearing on detected revocation, and error removal after recovery.

Implementation references:

- [Mewnu/Core/CalendarViewModel.swift](../../Mewnu/Core/CalendarViewModel.swift)
- [MewnuTests/CalendarViewModelTests.swift](../../MewnuTests/CalendarViewModelTests.swift)
