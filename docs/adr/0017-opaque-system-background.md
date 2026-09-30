# ADR-0017: Use an opaque system background for the menu

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

Transparent menu backgrounds can change contrast depending on the window behind them. Text, selection, and Today should remain legible on light and dark desktops.

## Decision

Use windowBackgroundColor as the opaque, system-dependent ContentView background. Give the unselected Today number the normal text color while retaining its accent outline. Use synthetic light and dark captures for visual review. Brand colors do not replace adaptive system UI colors.

## Alternatives

- Use translucent regularMaterial: a native effect, but background-dependent contrast.
- Use a fixed custom palette throughout the menu: controlled colors, but requires custom appearance and contrast maintenance.

## Consequences

An opaque adaptive background provides stable contrast against changing desktop content. It gives up the translucent menu appearance. Calendar colors still come from external stores, so their contrast requires separate review even when text and background use adaptive system colors.

## Implementation and validation

Review synthetic light and dark captures for background, selection, and Today. Check calendar-color contrast separately.

Implementation references:

- [Mewnu/Views/ContentView.swift](../../Mewnu/Views/ContentView.swift)
- [Mewnu/Views/MonthGridView.swift](../../Mewnu/Views/MonthGridView.swift)
- [scripts/documentation-screenshots.swift](../../scripts/documentation-screenshots.swift)
- [docs/SCREENSHOTS.md](../../docs/SCREENSHOTS.md)
