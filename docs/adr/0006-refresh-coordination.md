# ADR-0006: Debounce store changes and reject obsolete fetch results

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

Menu opening, activation, month navigation, and store notifications can create overlapping fetches. A slow older response must not overwrite the newly selected month.

## Decision

Debounce store notifications by 150 milliseconds. Each refresh advances a generation, cancels the previous load task, and accepts only results from the current generation. The service checks cancellation before enqueueing, before the queued fetch, and after return. Menu opening, app activation, day changes, and time-zone changes trigger their respective updates.

## Alternatives

- Fetch immediately for every notification while still rejecting obsolete results: updates begin sooner, but bursts enqueue redundant serial work. Debouncing trades a short delay for fewer queries.
- Poll periodically as the primary strategy: predictable scheduling, but adds queries when nothing changes and delays updates between intervals. Store notifications better match local changes.

## Consequences

Debouncing reduces redundant fetches at the cost of a 150-millisecond quiet interval for store notifications. Generations prevent obsolete results from changing the UI. Cancellation cannot interrupt a synchronous EventKit query already running, so that query may delay the newest fetch on the serial queue even though its result is discarded.

## Implementation and validation

A burst of store notifications produces one fetch. Late results cannot overwrite a newer month, and canceled tasks cannot return an acceptable snapshot.

Implementation references:

- [Mewnu/Core/CalendarViewModel.swift](../../Mewnu/Core/CalendarViewModel.swift)
- [Mewnu/Core/CalendarService.swift](../../Mewnu/Core/CalendarService.swift)
- [Mewnu/Views/ContentView.swift](../../Mewnu/Views/ContentView.swift)
- [MewnuTests/CalendarViewModelTests.swift](../../MewnuTests/CalendarViewModelTests.swift)
