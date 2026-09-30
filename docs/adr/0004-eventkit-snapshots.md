# ADR-0004: Fetch EventKit serially and return immutable value models

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

EventKit queries are synchronous and return mutable framework objects. Fetching large calendars must not block the UI.

## Decision

CalendarService encapsulates EventKit. A serial queue with userInitiated QoS queries one EKEventStore and converts results into CalendarSnapshot, CalendarInfo, and EventInfo before returning them. SwiftUI receives no EKEvent or EKCalendar objects.

## Alternatives

- Query on the main actor: simpler ownership, but synchronous EventKit work delays UI interaction.
- Use separate stores and concurrent fetches: more overlapping work, but requires coordinating store changes and snapshot consistency. One serial store favors predictable ownership for a single visible grid.

## Consequences

Value snapshots keep mutable EventKit objects out of presentation, and background fetching avoids blocking the main actor. Serialization makes a newer fetch wait for any query already running. Snapshot conversion also copies data and requires explicit mapping whenever a displayed field is added.

## Implementation and validation

Service tests verify snapshot mapping, off-main-thread fetching, and cancellation. Views use value models exclusively.

Implementation references:

- [Mewnu/Core/CalendarService.swift](../../Mewnu/Core/CalendarService.swift)
- [Mewnu/Core/Models.swift](../../Mewnu/Core/Models.swift)
- [MewnuTests/EventKitCalendarServiceTests.swift](../../MewnuTests/EventKitCalendarServiceTests.swift)
