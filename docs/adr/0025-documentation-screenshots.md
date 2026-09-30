# ADR-0025: Render documentation screenshots from real views and fixed fixtures

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

Screenshots must show the UI accurately without capturing personal calendar or desktop content.

## Decision

Use a separate documentation program to render real Core/View sources with fictional events on 16 September 2026, a Monday-first Gregorian calendar, UTC, English labels, and 2× resolution. Do not start MewnuApp or instantiate EventKitCalendarService. Isolate preferences in temporary defaults. Preset Help only in a temporary source copy. Document six states and allow additional dark captures.

## Alternatives

- Capture the running app in a controlled test-account session: verifies the live menu appearance, but depends on desktop, account, and clock state. The renderer fixes those inputs for documentation.
- Maintain manual mockups: gives full control of composition, but duplicates UI design and can drift from production views. Rendering those views keeps the images aligned.

## Consequences

Fixed fixtures and production views keep documentation captures consistent and free of personal calendar content. UI changes require regenerating and reviewing images. The separate renderer and temporary Help preset must track view changes; rendered images document appearance but do not verify permission dialogs, focus, or menu-window interaction.

## Implementation and validation

Render all six states from real views with a fixed date and fictional data without starting the production app or EventKit service.

Implementation references:

- [scripts/capture-screenshots.sh](../../scripts/capture-screenshots.sh)
- [scripts/documentation-screenshots.swift](../../scripts/documentation-screenshots.swift)
- [docs/SCREENSHOTS.md](../../docs/SCREENSHOTS.md)
- [README.md](../../README.md)
