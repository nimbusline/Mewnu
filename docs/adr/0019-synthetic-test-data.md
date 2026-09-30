# ADR-0019: Use isolated synthetic data for unit and UI tests

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

Automation should be reproducible and must not expose personal calendar entries in screenshots, logs, or test artifacts.

## Decision

Inject fake services, workspace, clocks, and calendars for unit tests. EventKit tests use FakeEventStore. The -ui-testing launch argument selects DemoCalendarService and a separate defaults suite reset at launch. Additional arguments simulate denial, 50 calendars, and a short window. Run UI sessions sequentially on the same Mac.

## Alternatives

- Run automation against a dedicated EventKit test account: exercises real integration, but depends on permission and synchronization state. Synthetic fixtures provide deterministic checks, with the test account used separately.
- Use unit tests with manual UI verification only: reduces automation setup, but repeated menu navigation and layout regressions require human checks. UI tests cover those repeatable interactions.

## Consequences

Isolated fixtures make automated checks repeatable and keep personal calendar content out of artifacts. Fake services do not exercise real permission dialogs, account synchronization, or recurrence behavior; those need integration checks on a test account. Sequential UI sessions avoid competing for the same menu bar but increase total test time.

## Implementation and validation

Unit and UI runs use isolated sample data and defaults. Run only one UI session per Mac; use a test account for real integration.

Implementation references:

- [Mewnu/MewnuApp.swift](../../Mewnu/MewnuApp.swift)
- [MewnuTests/EventKitCalendarServiceTests.swift](../../MewnuTests/EventKitCalendarServiceTests.swift)
- [MewnuTests/CalendarViewModelTests.swift](../../MewnuTests/CalendarViewModelTests.swift)
- [MewnuUITests/MewnuUITests.swift](../../MewnuUITests/MewnuUITests.swift)
