# ADR-0032: Validate complete keyboard, VoiceOver, and resize interactions

- **Status:** accepted
- **Decision date:** 2026-10-01
- **Documented:** 2026-10-01
- **Implementation:** implemented; automated evidence and remaining manual checks are recorded in [implementation validation](../ADR-IMPLEMENTATION-VALIDATION.md).

## Context

Localized accessibility labels and Escape tests cover parts of interaction. The current height UI test launches with different saved heights; its comment explains that CI runners do not reliably deliver synthetic drags to MenuBarExtra windows. This checks geometry and preferences but does not exercise dragging. [ADR-0015](0015-window-height.md) and [ADR-0016](0016-localization-accessibility.md) already require manual checks.

## Decision

Use an explicit interaction checklist with separate automated and manual evidence. Automate stable keyboard traversal and activation checks using synthetic calendars. Require manual keyboard-only, VoiceOver, and actual pointer-drag verification for relevant UI changes and before release. Add an automated drag test only where it reliably delivers the gesture; saved-height checks remain identified as preference/layout checks.

## Alternatives

- **Rely on labels and Escape tests.** Fast and stable, but does not establish that complete tasks or resize gestures work.
- **Require a CI drag test regardless of runner behavior.** Exercises the intended path when delivery works, but unreliable input creates failures unrelated to application behavior and still cannot replace VoiceOver use.

## Consequences

Evidence describes what was actually exercised. Manual verification adds recurring effort and requires a usable macOS session. Unperformed checks remain explicitly unverified.

## Implementation and validation

Record revision, macOS version, language, input method, expected result, actual result, and any unverified check, without personal calendar content. Cover opening the menu, month/day selection, filters, event details, Help, Escape return, permission recovery, and footer actions. Check visible focus, absence of focus traps, and VoiceOver names, state, and reading order in English and German.

Drag the handle larger and smaller; check preview, saved height after release and relaunch, display limits, and usable controls. Separately exercise VoiceOver height adjustment. Keep these results separate from saved-height UI tests and unit coverage.

References: [UI tests](../../MewnuUITests/MewnuUITests.swift), [ContentView](../../Mewnu/Views/ContentView.swift), [MonthGridView](../../Mewnu/Views/MonthGridView.swift), [release guide](../../RELEASING.md).
