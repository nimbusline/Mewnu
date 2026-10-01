# Documentation screenshots

The README images are rendered from Mewnu's real SwiftUI views, using fictional
calendars and events for **16 September 2026**. They are native view captures,
not illustrations or screenshots of a personal calendar. English labels, a
Monday-first Gregorian calendar, UTC, and a light appearance keep the examples
consistent. The renderer saves PNGs at twice the view's point dimensions.

## Regenerate the images

On macOS 26+ with Xcode 27+ selected:

```sh
scripts/capture-screenshots.sh
```

To inspect a new set without replacing the checked-in images:

```sh
scripts/capture-screenshots.sh /tmp/mewnu-screenshot-review
```

To check contrast in dark appearance without replacing the README images:

```sh
MEWNU_SCREENSHOT_APPEARANCE=dark scripts/capture-screenshots.sh /tmp/mewnu-dark-review
```

The script compiles the asset catalog and the current `Core/` and `Views/`
Swift sources into a temporary documentation executable. It does not launch
`MewnuApp`, instantiate `EventKitCalendarService`, request calendar permission,
or capture the desktop. Login-item and browser operations use a fake system boundary. The displayed version comes from project.yml. It uses isolated, temporary defaults and does not change
the running app's filters or window size.

A documentation-only initializer is appended to a temporary copy of
`ContentView.swift` to select the Help state. Its production view body and the
repository's app sources remain unchanged. Fixtures live in
[`scripts/documentation-screenshots.swift`](../scripts/documentation-screenshots.swift).

| Output in `docs/images/` | State |
| --- | --- |
| `mewnu-overview.png` | Month grid and the selected day's agenda |
| `mewnu-event-details.png` | A sample event's time, location, and notes |
| `mewnu-calendar-filter.png` | Calendar selection with Holidays hidden |
| `mewnu-expanded-agenda.png` | A taller window with the same day's events |
| `mewnu-help.png` | Built-in help |
| `mewnu-calendar-access.png` | Simulated denied permission and recovery actions |

The expanded height follows the app's screen-height limit. Use a display with
at least 924 points of available height to reproduce the full 900-point view.
Check every image for readable text, clipping, the current logo, and synthetic
data before committing it. These images document appearance; they do not
replace UI tests or permission tests with a real test account.

## Explore the app interactively with sample data

After the README's development build, quit any running Mewnu instance. Then run:

```sh
open build/DerivedData/Build/Products/Debug/Mewnu.app --args -ui-testing
```

For the permission recovery view, add `-ui-testing-denied`. For a busy calendar,
add `-ui-testing-many-calendars`:

```sh
open build/DerivedData/Build/Products/Debug/Mewnu.app --args \
  -ui-testing -ui-testing-many-calendars
```

These modes use `DemoCalendarService` and a separate defaults suite. Their sample
date is the current day; the scripted README captures use the fixed fixtures
above. Never commit screenshots, logs, or recordings containing personal calendar
data.
