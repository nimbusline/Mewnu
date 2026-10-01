# ADR-0031: Make complete event content and important errors readable

- **Status:** accepted
- **Decision date:** 2026-10-01
- **Documented:** 2026-10-01
- **Implementation:** implemented; automated evidence and remaining manual checks are recorded in [implementation validation](../ADR-IMPLEMENTATION-VALIDATION.md).

## Context

At review time, the menu had a fixed 364-point width, one-line agenda titles, a 120-point notes area, and one-line footer errors plus a tooltip. These constraints can make long titles, locations, notes, and German messages difficult to read. [ADR-0015](0015-window-height.md) defines fixed width and adjustable height; [ADR-0007](0007-failure-state.md) defines data retention after errors.

## Decision

Retain the compact overview and current width while providing complete, wrapping titles and locations in a scrollable detail view. Let notes use the remaining detail space as the window grows rather than a fixed 120-point maximum. Present important errors in a wrapping, accessible message area whose full text remains reachable at the minimum height, with recovery actions where applicable. Keep footer actions reachable.

Width resizing remains a separate possible decision if these changes fail the long-content checks. Preserve same-month data retention and permission-revocation behavior.

## Alternatives

- **Allow width resizing immediately.** Gives long text more room, but requires a new window-sizing contract and additional grid, screen-bound, and persistence work.
- **Use tooltips for full content.** Preserves compact geometry, but makes reading dependent on hovering and offers poor access to long notes and important errors.

## Consequences

Full content becomes reachable while the overview stays compact. Wrapping uses more vertical space and scrolling needs careful focus handling. Long error messages must not displace navigation or expose calendar content in logs.

## Implementation and validation

Use synthetic long titles, multiline locations, several paragraphs of notes, unbroken text, and long German and English errors. Check minimum and expanded heights, small displays, detail scrolling, keyboard focus, and VoiceOver reading order. Confirm full content remains reachable and controls do not overlap. ContentView implements the scrollable detail and error areas. The validation record distinguishes completed UI checks from remaining manual checks.

References: [ContentView](../../Mewnu/Views/ContentView.swift), [rendering tests](../../MewnuTests/ContentViewRenderingTests.swift), [UI tests](../../MewnuUITests/MewnuUITests.swift), [ADR-0016](0016-localization-accessibility.md).
