# ADR-0028: Decode a bounded set of entities in calendar and event titles

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

Some calendar sources supply entity-encoded titles. Visible sequences such as `&amp;` obscure names, but titles remain plain text and do not require HTML presentation.

## Decision

Normalize calendar and event titles at the snapshot boundary with CalendarText. Decode `amp`, `lt`, `gt`, `quot`, `apos`, and `nbsp` entities and valid decimal or `#x` hexadecimal Unicode entities, including their required semicolons. Apply one decoding pass; preserve unknown and invalid sequences. Display the result as plain text. Locations and notes are passed through without entity decoding.

## Alternatives

- Preserve every title exactly as supplied: avoids normalization and keeps literal entity syntax, but leaves common encoded characters visible. Bounded decoding improves readability for those sources.
- Use a general HTML importer: supports more entities and markup, but introduces document interpretation and formatting behavior beyond title normalization. A small decoder keeps the transformation explicit and testable.

## Consequences

Recognized entities become readable characters without an HTML rendering dependency. Literal text matching a supported entity is also transformed; unknown encodings remain visible. One pass preserves nested encoding after the first replacement, and adding supported entities changes display behavior and requires focused review.

## Implementation and validation

Verify named and numeric decoding, unchanged plain text, and preservation of unknown or invalid entities. Review one-pass behavior and plain-text presentation when changing the decoder; these checks are separate from date/time formatting.

Implementation references:

- [Mewnu/Core/CalendarText.swift](../../Mewnu/Core/CalendarText.swift)
- [Mewnu/Core/CalendarService.swift](../../Mewnu/Core/CalendarService.swift)
- [MewnuTests/CalendarTextTests.swift](../../MewnuTests/CalendarTextTests.swift)
