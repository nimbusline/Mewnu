# ADR-0003: Request Full Access for reading and provide permission recovery

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

EventKit reports several authorization states, while the product needs to read events. After denial, users need a clear route to restore access.

## Decision

Treat only fullAccess as allowed, map notDetermined to undetermined, and map all other states to denied. activate requests permission only when undetermined. For denied access, offer Calendar settings and a status recheck. App activation also triggers refresh. Enable the app sandbox and calendar entitlement.

## Alternatives

- Request access at application launch: permission is ready before the menu opens, but the request appears before users reach the calendar view. Requesting on activation places it in the relevant UI context.
- Provide manual settings instructions without a recovery action: fewer system-integration paths, but users must find Calendar privacy settings themselves. A direct settings action and recheck shorten that recovery flow.

## Consequences

Permission states and recovery actions provide a consistent access flow. macOS grants Full Access even though Mewnu only reads, so the UI must explain the requested capability and the implementation must preserve the read-only boundary. Revocation is reflected when authorization is next checked during refresh.

## Implementation and validation

Test authorization states and request failures. Check recovery actions in the UI and real permission changes using a test account.

Implementation references:

- [Mewnu/Core/CalendarService.swift](../../Mewnu/Core/CalendarService.swift)
- [Mewnu/Views/ContentView.swift](../../Mewnu/Views/ContentView.swift)
- [Mewnu/Mewnu.entitlements](../../Mewnu/Mewnu.entitlements)
- [MewnuTests/EventKitCalendarServiceTests.swift](../../MewnuTests/EventKitCalendarServiceTests.swift)
