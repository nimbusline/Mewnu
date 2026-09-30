# ADR-0016: Support English, German, VoiceOver, and keyboard navigation

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

A compact icon-based interface must be usable without relying solely on a mouse or color perception. Long German labels must fit the fixed width.

## Decision

Maintain English and German strings together; dates and week layout follow system settings. Give icon buttons labels and tooltips, hide decorative elements from VoiceOver, and supplement calendar colors with names. Support Escape navigation. Stack permission actions vertically in a scrollable area and align filter checkboxes to the left. Use language-independent UI identifiers and explicitly test German labels.

## Alternatives

- Use separate layouts for each language: allows language-specific spacing, but duplicates view maintenance. Shared layouts with synchronized strings keep interaction consistent.
- Make only individual controls accessible: simpler grouping, but leaves date, selection, and calendar membership to be inferred across controls. Explicit descriptions and decorative-element exclusion give VoiceOver clearer context.

## Consequences

Names, localized labels, and keyboard actions make the compact UI usable beyond icons and colors. Every new control or string creates work in both languages and in accessibility review. The fixed width requires layout checks with longer labels, and automated UI checks must be complemented by manual VoiceOver and keyboard use.

## Implementation and validation

Keep localization keys synchronized. UI tests check German permission buttons; manually check keyboard use, VoiceOver, long text, and resizing with sample data.

Implementation references:

- [Mewnu/Views/ContentView.swift](../../Mewnu/Views/ContentView.swift)
- [Mewnu/Views/MonthGridView.swift](../../Mewnu/Views/MonthGridView.swift)
- [Mewnu/de.lproj/Localizable.strings](../../Mewnu/de.lproj/Localizable.strings)
- [Mewnu/en.lproj/Localizable.strings](../../Mewnu/en.lproj/Localizable.strings)
- [MewnuUITests/MewnuUITests.swift](../../MewnuUITests/MewnuUITests.swift)
