# ADR-0015: Persist adjustable window height with fixed width

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

A compact month view must leave enough agenda space for busy days. Users should be able to adjust height and retain it across restarts.

## Decision

Keep width at 364 points and default height at 620. A bottom drag handle previews height and saves it on release. The regular range is 500–1,000 points, capped at visible screen height minus 24; smaller displays may also lower the minimum. VoiceOver adjusts height in 40-point steps.

## Alternatives

- Use a fixed window size: simpler, but limits space on busy days.
- Allow unrestricted native width and height resizing: flexible, but adds layout and window-control work.

## Consequences

Extra height gives the agenda more room while preserving a predictable width. The fixed width constrains long labels and detail text. Custom dragging, persistence, screen bounds, and VoiceOver adjustment add maintenance beyond a fixed-size menu, especially when users move between displays with different available heights.

## Implementation and validation

Unit tests cover persistence, display limits, and invalid values. UI tests cover two window heights. Verify dragging and VoiceOver adjustment manually.

Implementation references:

- [Mewnu/Core/MenuWindowSize.swift](../../Mewnu/Core/MenuWindowSize.swift)
- [Mewnu/Views/ContentView.swift](../../Mewnu/Views/ContentView.swift)
- [MewnuTests/MenuWindowSizeTests.swift](../../MewnuTests/MenuWindowSizeTests.swift)
- [MewnuUITests/MewnuUITests.swift](../../MewnuUITests/MewnuUITests.swift)
