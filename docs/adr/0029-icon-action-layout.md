# ADR-0029: Place Help in the footer and use consistent icon buttons

- **Status:** accepted
- **Decision date:** 2026-09-30
- **Documented:** 2026-09-30

## Context

The previous layout placed Help and calendar selection in the header, with Open Apple Calendar and Quit in the footer. The four icon buttons had equal 28-point label frames but different styling: Help and the footer used a plain button style, calendar selection used the default style, and the footer inherited a caption font.

Calendar selection is a persistent app preference, yet its immediate effect is to change the events and markers displayed in the calendar. Persistence alone therefore does not determine a control's position. The layout should express the relationship between an action and the content it affects, while presenting comparable controls consistently.

## Decision

Keep calendar selection in the header, close to the calendar whose visible content it controls. Move Help to the footer alongside Open Apple Calendar and Quit. Order the footer actions from left to right as Help, Open Apple Calendar, and Quit, with Quit at the trailing edge of the action group.

Use a shared icon-button presentation for these four actions: the same explicit symbol size and weight, a minimum 28 × 28-point clickable area, consistent spacing within action groups, and consistent hover, pressed, and keyboard-focus feedback. Use system foreground colors and preserve a visible focus indicator. Action labels and symbols continue to communicate their different purposes.

Help remains available in every content state. Its footer button continues to become Back while Help is shown; Back and Escape return to the overview. Calendar selection retains its existing visibility rules and return behavior. This placement supplements [ADR-0013](0013-in-window-navigation.md); it does not change the single-window navigation model.

## Alternatives

- **Keep the current positions and only align styling.** This is the smallest change and preserves familiar locations. However, Help has no particular relationship to the displayed calendar and fits the footer's supporting actions. Moving it makes that grouping clearer at the cost of a changed location.
- **Move all four actions to the footer.** This produces one compact group and reflects that calendar selection is an app preference. It also separates the filter from the content it changes and puts it beside actions that leave or terminate Mewnu. Proximity to the affected content is the stronger reason to keep selection above.
- **Move all four actions to the header.** This makes every action visible near the app title, but concentrates controls above the calendar and puts Quit closer to calendar interaction. A separate footer keeps supporting actions reachable without crowding the header.

## Consequences

The header concentrates on calendar presentation; the footer groups help, opening Apple's app, and exiting Mewnu. Shared styling prevents incidental differences between otherwise comparable controls. Users accustomed to Help in the header must learn its new location, and the footer needs room for a third action alongside any error message. Proximity and grouping are design judgments, not measured usability improvements.

## Implementation and validation

The accepted layout is implemented in ContentView with a shared icon-button view and the native borderless button style for interaction feedback. Validate changes to this layout as follows:

- Verify action order, consistent icon metrics, full clickable areas, and interaction feedback with synthetic data in light and dark appearance.
- Check the overview, calendar selection, event details, Help, and permission recovery. Help and its Back action remain reachable; Escape preserves the navigation behavior defined in ADR-0013.
- Check keyboard traversal and visible focus, localized VoiceOver labels and tooltips in English and German, and stable UI identifiers, following [ADR-0016](0016-localization-accessibility.md).
- Check minimum and expanded window heights, including a synthetic footer error, for clipping, overlapping actions, and resize-handle interference.
- Adapt relevant UI checks and update the README control description and synthetic documentation screenshots to match the new Help location. Record automated test results separately from manual checks of focus, VoiceOver, and interaction feedback.

Implementation references:

- [Mewnu/Views/ContentView.swift](../../Mewnu/Views/ContentView.swift)
- [MewnuUITests/MewnuUITests.swift](../../MewnuUITests/MewnuUITests.swift)
- [README.md](../../README.md)
- [Screenshot guide](../SCREENSHOTS.md)
