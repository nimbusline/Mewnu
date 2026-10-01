# ADR-0001: Provide a local, read-only companion to Apple Calendar

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

The menu bar should provide quick access to a second calendar view without introducing another account or synchronization system.

## Decision

Mewnu only reads the calendars available through Apple Calendar. Account setup, synchronization, and editing remain with macOS and Apple Calendar. The app has no account system, backend, analytics, or persistent event-content storage. Only calendar filters and window height are saved locally.

## Alternatives

- Build a calendar client with editing: more features, but requires write access and substantially greater product responsibility.
- Implement CalDAV or cloud access directly: independent of Apple Calendar, but requires credentials, synchronization, and network operations.

## Consequences

Account management and synchronization remain centralized in Apple Calendar, and event content is not persisted. Users must switch to Apple Calendar to edit events or configure accounts. Displayed data depends on the local EventKit store and its synchronization state; Mewnu cannot resolve account synchronization failures itself.

## Implementation and validation

The app contains no EventKit write operations, account login, or event persistence. Editing actions open Apple Calendar.

Implementation references:

- [README.md](../../README.md)
- [Mewnu/Core/CalendarService.swift](../../Mewnu/Core/CalendarService.swift)

## Extension on 2026-10-01

[ADR-0038](0038-signed-automatic-updates.md) adds automatic updates. Software update requests to GitHub are now permitted as a separate distribution concern; calendar data remains local. Update preferences are also stored locally by Sparkle.
