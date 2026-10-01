# ADR-0008: Use a 42-day grid, exclusive ends, and calendar day boundaries

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

Month edges, all-day events, and daylight-saving transitions require consistent day-overlap rules.

## Decision

Display six weeks containing 42 days and respect calendar.firstWeekday. An event overlaps a day when start < day.end and end > day.start; its end is exclusive. Obtain day boundaries from Calendar rather than adding a fixed 86,400 seconds. Skip imported events without positive duration.

**Amendment accepted 2026-10-01:** [ADR-0030](0030-zero-duration-events.md) replaces the positive-duration-only rule for timed events with support for zero-duration point events. Negative intervals and zero-duration all-day entries remain invalid. The grid and exclusive-end rules above continue to apply to positive intervals. This amendment is implemented; see [implementation validation](../ADR-IMPLEMENTATION-VALIDATION.md) for evidence and remaining integration checks.

## Alternatives

- Use a variable four-to-six-week grid with calendar-based boundaries: fewer adjacent-month cells, but changes menu geometry between months. Six fixed weeks keep the layout stable.
- Normalize dates in a fixed time zone: deterministic boundaries, but differs from the user's local calendar around day changes. System Calendar boundaries match the displayed dates and week settings.

## Consequences

The fixed grid keeps navigation geometry stable and includes adjacent-month context, but fetches and displays days outside the selected month. Calendar-based overlap rules handle daylight-saving changes and exclusive ends. Importing only positive durations excludes zero-length entries, so they never appear in the agenda or markers.

## Implementation and validation

Test 42 grid days, configured week starts, month edges, exclusive midnight ends, and daylight-saving transitions.

Implementation references:

- [Mewnu/Core/CalendarMath.swift](../../Mewnu/Core/CalendarMath.swift)
- [Mewnu/Core/CalendarService.swift](../../Mewnu/Core/CalendarService.swift)
- [MewnuTests/CalendarMathTests.swift](../../MewnuTests/CalendarMathTests.swift)
