# ADR-0010: Build filtered daily indexes once per snapshot

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

The grid requests information for 42 days. Filtering and sorting every event during each redraw repeats unnecessary work.

## Decision

After a fetch or filter change, CalendarViewModel builds daily indexes for visible events and their calendars. CalendarMath visits only grid days overlapped by each event. Sort all-day events first, then by start time, localized title, and ID. Use LazyVStack within a ScrollView for the agenda.

## Alternatives

- Search all events for each cell: simpler, but repeats computation during rendering.
- Use a persistent database index or a background index: more scalable, but adds persistence or concurrency overhead without an established need.

## Consequences

Prepared indexes reduce repeated work during rendering and retain the complete daily agenda. Rebuilding on each snapshot or filter change consumes main-actor time and additional memory, including entries for each overlapping grid day of a multiday event. Volume tests establish completeness and order; responsiveness requires separate measurement.

## Implementation and validation

All 10,000 daily events remain available and sorted. Filter and snapshot changes rebuild the index. Measure responsiveness separately.

Implementation references:

- [Mewnu/Core/CalendarMath.swift](../../Mewnu/Core/CalendarMath.swift)
- [Mewnu/Core/CalendarViewModel.swift](../../Mewnu/Core/CalendarViewModel.swift)
- [Mewnu/Views/ContentView.swift](../../Mewnu/Views/ContentView.swift)
- [MewnuTests/CalendarMathTests.swift](../../MewnuTests/CalendarMathTests.swift)
