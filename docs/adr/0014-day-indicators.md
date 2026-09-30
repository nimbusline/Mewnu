# ADR-0014: Compact calendar indicators and distinguish Today from selection

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

Day cells should communicate calendar membership without becoming crowded when many calendars have events. Today must remain identifiable when another day is selected.

## Decision

Show at most one dot per visible calendar with events, using its calendar color. Show all dots for up to four calendars; at five or more, show three dots and the remaining count, capped visually at 99+. Fill the selected day with the accent color. Mark unselected Today with an accent outline and emphasized number. VoiceOver describes date, Today, selection, and calendar indicators.

## Alternatives

- Show one marker per event: indicates density, but duplicates colors and crowds busy days. Deduplicated calendar dots favor membership.
- Show only a total calendar count: uses less space at high counts, but omits visible calendar colors even on quiet days. Dots with overflow retain those colors when space permits.

## Consequences

Calendar dots communicate membership rather than event volume. Overflow keeps cells compact, but hides the individual colors of calendars beyond the first three; the agenda and filters provide their names. Separate Today and selection styling requires appearance and VoiceOver checks for both states and their combination.

## Implementation and validation

Test deduplication, filter effects, four dots versus three dots with overflow, and separate Today and selection states.

Implementation references:

- [Mewnu/Views/MonthGridView.swift](../../Mewnu/Views/MonthGridView.swift)
- [Mewnu/Core/CalendarViewModel.swift](../../Mewnu/Core/CalendarViewModel.swift)
- [MewnuTests/ContentViewRenderingTests.swift](../../MewnuTests/ContentViewRenderingTests.swift)
- [MewnuTests/CalendarViewModelTests.swift](../../MewnuTests/CalendarViewModelTests.swift)
