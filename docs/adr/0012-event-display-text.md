# ADR-0012: Centralize event time and date-range formatting

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

An event can overlap several calendar days. Its agenda label must describe its relationship to the selected day, while details must show the complete range using the user's calendar and locale.

## Decision

Use EventDisplayText for agenda and detail formatting with the supplied Calendar and Locale. All-day rows show All day. Timed rows show the start time when the event starts on the selected day; otherwise, show Until … when it ends by that day's end, or Continues when it spans beyond it. Details show the complete date/time range. For all-day details, display the inclusive final day corresponding to the exclusive end.

## Alternatives

- Format independently in agenda and detail views: keeps formatting close to each view, but duplicates calendar and range rules. One formatter makes those rules consistently testable.
- Show the complete range in every agenda row: retains all timing information, but repeats dates and consumes space in the narrow menu. Day-relative labels keep the agenda concise while details provide the full range.

## Consequences

Shared rules keep agenda labels and detail ranges consistent across languages and day boundaries. Agenda rows intentionally omit part of the range, so users open details for complete timing. Changes to wording or range semantics affect both presentations and require checks for overnight, multiday, and all-day events.

## Implementation and validation

Check same-day start times, overnight final-day labels, intermediate-day continuation, and all-day ranges with an inclusive final day. Use explicit calendars, time zones, and locales for reproducible cases.

Implementation references:

- [Mewnu/Core/EventDisplayText.swift](../../Mewnu/Core/EventDisplayText.swift)
- [MewnuTests/EventDisplayTextTests.swift](../../MewnuTests/EventDisplayTextTests.swift)
