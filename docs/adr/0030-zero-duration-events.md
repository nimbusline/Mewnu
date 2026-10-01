# ADR-0030: Treat zero-duration timed events separately from invalid intervals

- **Status:** accepted
- **Decision date:** 2026-10-01
- **Documented:** 2026-10-01
- **Implementation:** implemented; automated evidence and remaining manual checks are recorded in [implementation validation](../ADR-IMPLEMENTATION-VALIDATION.md).

## Context

At the reviewed baseline, CalendarService rejected events whose end is equal to or earlier than their start. A calendar source can supply a timed entry representing a single instant. The baseline malformed-event test covered an equal start and end, but did not separately establish behavior for negative duration. [ADR-0008](0008-calendar-day-boundaries.md) currently requires positive duration.

## Decision

Support timed events with equal start and end as point events on the calendar day containing their start. Display one time in details and include them consistently in the agenda and day markers. Do not invent a duration or modify EventKit data. Continue rejecting negative durations and missing dates. Reject zero-duration all-day entries because they do not describe a valid all-day interval.

This decision replaces ADR-0008's positive-duration-only import rule for timed point events; its exclusive-end rule continues to apply to positive intervals. CalendarService, both day lookup paths, and display formatting implement this rule.

## Alternatives

- **Reject all nonpositive intervals.** Keeps current behavior and simple overlap rules, but silently omits potentially useful timed entries.
- **Assign an artificial duration.** Reuses interval logic, but changes the meaning of source data and can introduce false day overlaps.

## Consequences

Point entries remain visible without treating malformed negative intervals as valid. Service conversion, both day lookup paths, and display formatting need consistent treatment. EventKit query behavior still needs checking with a synthetic test calendar.

## Implementation and validation

Validation requirements (completed automated checks and remaining integration checks are listed in the validation record):

- Separate service tests for zero timed duration, zero all-day duration, negative duration, missing dates, and ordinary positive duration.
- Match `events(on:)` and `dayIndex` at midnight, grid edges, and daylight-saving transitions. A point at midnight belongs only to the new day.
- Test row/detail formatting in English and German, ordering, filtering, and calendar markers.

References: [Service](../../Mewnu/Core/CalendarService.swift), [Math](../../Mewnu/Core/CalendarMath.swift), [DisplayText](../../Mewnu/Core/EventDisplayText.swift), [service tests](../../MewnuTests/EventKitCalendarServiceTests.swift), [math tests](../../MewnuTests/CalendarMathTests.swift), [display tests](../../MewnuTests/EventDisplayTextTests.swift).
