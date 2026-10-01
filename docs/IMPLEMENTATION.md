# Mewnu implementation guide

The ADRs define architecture. This guide specifies product and interface contracts, behavior rules, and acceptance criteria. The views, assets, and [synthetic screenshots](SCREENSHOTS.md) document the UI appearance.

Documentation edition: 2026-10-01. This contract covers the defined product scope. See [architecture references and validation](ARCHITECTURE-REFERENCES.md) for technical references and validation resources.

## Product contract

Mewnu is a native macOS 26+ menu bar app for Apple silicon and Intel. Clicking the cat opens a window without a Dock icon or separate main window. It provides a month view, daily agenda, calendar filters, event details, Help, and permission recovery. It reads existing Apple Calendar accounts; editing remains in Apple Calendar. It has no account system, backend, analytics, event persistence, or calendar network service. Software updates use Sparkle.

Support English and German. Dates, times, time zones, and week starts follow system settings. Personal calendar content must not enter development logs, test artifacts, or documentation.

## Data and system boundaries

| Component | Contract |
| --- | --- |
| CalendarAccess | undetermined, allowed, denied; only EventKit fullAccess maps to allowed |
| CalendarInfo | Calendar identity, display title, and display color |
| EventInfo | id, calendarID, title, start, end, isAllDay, optional location and notes |
| CalendarSnapshot | Arrays of CalendarInfo and EventInfo; only value models leave the fetch boundary |
| CalendarService | Read access, async requestAccess, async throwing load(from:to:), onChange callback; main-actor interface |
| CalendarWorkspace | Find/open Apple Calendar and open Calendar privacy settings; report application-opening errors |
| CalendarViewModel | Main-actor permission, visible-month, date, selected-event, filter, refresh-task, and index state |
| AppPreferences | Actual native login-item state, explicit registration, installed version, and browser release action; injectable system boundary |
| MenuWindowSize | Fixed width, persisted height, and safe bounds including NaN and infinity |

Map calendars with a system-accent color fallback and title sorting. Calendar colors shown in the UI reflect the latest accepted snapshot. Apply [bounded entity decoding](adr/0028-calendar-title-decoding.md) to calendar and event titles; display missing titles using the localized Untitled event label. Discard events with missing calendar/date fields or negative duration. Accept timed zero-duration entries as point events; reject zero-duration all-day entries. Combine calendar identity, event identity with fallback, and start time for occurrence IDs. Do not expand recurrence rules locally.

Model equality and helper algorithms are implementation details unless required by an ADR. Their current form does not add a product requirement; observable behavior and the system boundaries above govern changes.

## Behavior and state transitions

| Trigger | Expected behavior |
| --- | --- |
| Open menu | activate updates Today, reads authorization, requests only when undetermined, and starts refresh |
| Missing permission | refresh clears calendars, events, indexes, and detail selection; show guidance and recovery actions |
| Recheck / app becomes active | refresh reads permission again and fetches when allowed |
| Store notifications | Debounce by 150 ms; a new refresh invalidates older results and cancels their task |
| Month arrow | Select the first day of the adjacent month, clear details, and reload the grid |
| Day in current month | Change date selection, clear details, and use the existing index |
| Day in adjacent month | Change selection and visible month, clear details, and fetch the new grid |
| Today | Set selection and visible month to now, clear details, and fetch |
| Day/time-zone change | Follow the new Today only if the selection previously followed Today; retain deliberate other-date selection; fetch |
| Filter change | Save hidden IDs and rebuild daily indexes without another store fetch |
| Successful fetch | Accept the current snapshot, rebuild indexes, update or clear selected details by ID, and clear the error |
| Transient failure | Retain same-month data and show the error; different-month event data is cleared before fetching |
| Select event | Replace the menu's main content with details |
| Close details / Escape | Return to the overview while keeping the menu window open |
| Open Help | Clear detail and filter selection; Back or Escape exits Help |
| Calendar / power icon | Open Apple Calendar or terminate the app; localize labels and tooltips |

The header keeps calendar selection close to its affected content. The footer orders Help (Back while Help is open), Open Apple Calendar, and Quit from left to right. These four actions share icon metrics, clickable areas, and native interaction feedback; see [ADR-0029](adr/0029-icon-action-layout.md).

Presentation prioritizes Help, then permission state. With allowed access, details take precedence over filters and the calendar. Show errors as wrapping text in a separate scrollable area above the footer. Preserve reachable footer actions and the resize handle. A separate loading spinner or elaborate error dialog is outside the defined scope.

## Day and display rules

- Build 42 grid days from the system's first weekday at or before the month start. Fetch from the first grid day to the day after the last grid day.
- A positive-duration event overlaps a day when start < day.end and end > day.start. A timed point event belongs only to the day where day.start ≤ start < day.end. Ends are exclusive; use Calendar day boundaries.
- Sort all-day events first, then by start, localized title, and ID. Use a scrollable LazyVStack agenda and show the visible daily event count.
- Show one colored dot per visible calendar with events. Show all dots for up to four calendars; above four, show three dots plus the remainder. Remainders above 99 display as 99+.
- Mark Today independently of selection. Selection uses an accent fill and white text. Unselected Today uses an accent outline and emphasized number in normal text color. Dim dates outside the visible month.
- All-day time labels show All day. Timed labels show the start time when the event starts on the selected day; otherwise, show Until … when it ends by that day's end, or Continues when it spans beyond it. Details show complete date/time ranges, one date/time for point events, and the inclusive final day for all-day events.
- Details show title, calendar, time, and optional location/notes. Title, location, and plain-text notes wrap in one scrollable detail area using the remaining window height; the close button stays outside it. No HTML rendering or event editing is provided.
- Filters show checkbox, calendar color, and title without account names. Align checkboxes left and allow two lines for long names.

## Window, persistence, and accessibility

Use 364-point width, 620-point default height, and a regular 500–1,000-point range. Available height is visible screen height minus 24, capped at 1,000. Very small displays also reduce the minimum. Determine the screen using pointer location or the main screen. Preview a drag locally and save on release. VoiceOver adjusts in 40-point steps.

Persist only hiddenCalendarIDs and menuWindowHeight for product functionality. New calendars are visible; existing hidden IDs remain saved. Do not persist event snapshots. Test mode uses a separate defaults suite cleared on launch; an explicit test-only relaunch option preserves it for resize persistence checks. Login-item registration is managed by ServiceManagement, not a saved Boolean. UI tests use a fake registration and browser boundary.

Give icon buttons localized labels and tooltips with 28 × 28-point click areas. Date cells have language-independent YYYY-MM-DD identifiers and VoiceOver information for date, Today, selection, and calendars. Make the longer German permission view scrollable and stack its actions vertically. Use an opaque system window background and calendar colors supplied by the store.

Launch at login is optional and initially unregistered; Help reflects system registration, approval, and error states. Re-read it when the app becomes active. Help displays the installed version and updater controls. AppUpdater wraps the Sparkle driver; tests/previews use a synthetic driver. Checks and unattended installation default off and are persisted by Sparkle. Explicit checks or enabled automatic checks request the fixed GitHub appcast; archive and feed signatures are required. Calendar refresh does not contact the updater. The browser release link remains a fallback. See ADR-0038.

Keyboard actions: Command-T for Today, Command-left/right for months, Shift-Command-F for filters, Shift-Command-H for Help/Back, and Escape for return. Full keyboard traversal, focus visibility, VoiceOver reading order, and actual dragging require the [interaction checklist](INTERACTION-VALIDATION.md).

## Implementation sequence

1. [Product scope](adr/0001-product-scope.md), [native entry point](adr/0002-native-menu-bar.md), and [project generation](adr/0021-project-generation.md): set up the project, targets, bundle ID, entitlements, and MenuBarExtra.
2. [Service](adr/0004-eventkit-snapshots.md), [state model](adr/0005-view-model-boundaries.md), and [permissions](adr/0003-calendar-permissions.md): build a fake service first, then the serial EventKit adapter.
3. [Day boundaries](adr/0008-calendar-day-boundaries.md), [occurrence IDs](adr/0009-recurrence-identity.md), [daily index](adr/0010-daily-event-index.md), [time formatting](adr/0012-event-display-text.md), and [title decoding](adr/0028-calendar-title-decoding.md): implement rules using fixed test cases.
4. [Refresh coordination](adr/0006-refresh-coordination.md), [failure behavior](adr/0007-failure-state.md), and [preferences](adr/0011-local-preferences.md): add race and authorization-change tests.
5. [Navigation](adr/0013-in-window-navigation.md), [indicators](adr/0014-day-indicators.md), [height](adr/0015-window-height.md), [accessibility](adr/0016-localization-accessibility.md), [contrast](adr/0017-opaque-system-background.md), and [brand](adr/0018-vector-brand-assets.md): complete the UI with sample data.
6. [Test strategy](adr/0019-synthetic-test-data.md), [coverage](adr/0020-core-coverage-gate.md), [universal builds](adr/0022-universal-build.md), and [DMG distribution](adr/0023-signed-dmg-release.md): implement verification and distribution, then check real integration using a test account.

## Acceptance criteria

| Area | Minimum evidence for the product contract |
| --- | --- |
| Authorization | undetermined/allowed/denied, request denial and errors; no displayed events after detected revocation |
| Concurrency | Older month responses cannot overwrite newer months; canceled fetches yield no usable snapshot; store notifications are grouped |
| Failures | Retain same-month snapshots on transient errors; do not show an older month's events; successful fetches clear errors |
| Time | Exclusive midnight ends, all-day/overnight events, multiday spans, month edges, and DST |
| Titles and colors | Known and numeric entities decode; unknown and invalid entities remain; accepted snapshots update calendar colors |
| Volume | 10,000 daily events remain complete and sorted; 50 calendars are deduplicated, filtered, and compacted |
| Preferences | Recreating models retains filters and height; small displays, NaN, and infinity are bounded safely |
| Navigation | Repeated details open/close; Help and Escape return; German permission content fits the width |
| UI height | Different starting values change actual window geometry; verify dragging locally/manually |
| Language and access | Matching EN/DE keys; manual keyboard and VoiceOver checks with synthetic data; light/dark appearance |
| Build | Successful generation and build; verify both universal slices with lipo |
| Quality | Focused tests and normal CI; 95 percent coverage for each of the five explicitly listed core files |
| Real integration | Test account: permission grant/revocation, synchronization, recurrence exceptions, and large calendars |
| Distribution | Developer ID signature, notarization, stapling, Gatekeeper, DMG contents, SHA-256, and installation; verify workflow results separately |

The [unit tests](../MewnuTests), [UI tests](../MewnuUITests/MewnuUITests.swift), and [README commands](../README.md) provide executable examples. An implementation is verified only after appropriate tests and required manual checks succeed.
