# Architecture Decision Records

These 37 ADRs document Mewnu's product scope, architecture, presentation, test strategy, and release process. Each record explains the problem, selected or proposed solution, viable alternatives, consequences, and implementation criteria.

The ADRs use the present tense as implementation guidance. `accepted` identifies a decision that applies to Mewnu. The documentation date records this edition; it does not state when a decision was originally made. Documentation dates alone do not establish a historical meeting or approval timeline; an explicit decision date records acceptance where known.

`proposed` records describe changes under review, not implemented behavior or completed validation. ADRs 0030–0037 address the review of event durations, long content, interaction verification, reproducible project generation, repository corrections, and everyday convenience. Security support and entitlement syntax, and launch at login and updates, have separate records because each can be implemented independently. ADRs 0030–0037 were explicitly accepted on 2026-10-01. Their implementation and local verification are described in [the validation record](../ADR-IMPLEMENTATION-VALIDATION.md); required manual and release checks remain explicitly unverified. ADR-0030 updates the duration rule in ADR-0008; ADR-0033 extends ADR-0021 with exact generator pinning and drift checks. ADR-0038 supersedes ADR-0037 with the requested automatic updater and revises the network/dependency and release contracts. Other existing decisions continue to apply.

The scope covers significant application and development decisions. Variable names and one-time administrative actions do not require separate ADRs.

| ADR | Decision | Status | Documented |
| --- | --- | --- | --- |
| [0001](0001-product-scope.md) | Provide a local, read-only companion to Apple Calendar | accepted | 2026-09-30 |
| [0002](0002-native-menu-bar.md) | Use native SwiftUI without a Dock icon or main window | accepted | 2026-09-30 |
| [0003](0003-calendar-permissions.md) | Request Full Access for reading and provide permission recovery | accepted | 2026-09-30 |
| [0004](0004-eventkit-snapshots.md) | Fetch EventKit serially and return immutable value models | accepted | 2026-09-30 |
| [0005](0005-view-model-boundaries.md) | Use one main-actor view model with injectable system boundaries | accepted | 2026-09-30 |
| [0006](0006-refresh-coordination.md) | Debounce store changes and reject obsolete fetch results | accepted | 2026-09-30 |
| [0007](0007-failure-state.md) | Retain same-month data on fetch failure and clear it on lost access | accepted | 2026-09-30 |
| [0008](0008-calendar-day-boundaries.md) | Use a 42-day grid, exclusive ends, and calendar day boundaries | accepted | 2026-09-30 |
| [0009](0009-recurrence-identity.md) | Use EventKit occurrences and identify each occurrence separately | accepted | 2026-09-30 |
| [0010](0010-daily-event-index.md) | Build filtered daily indexes once per snapshot | accepted | 2026-09-30 |
| [0011](0011-local-preferences.md) | Save hidden calendar IDs and window height in UserDefaults | accepted | 2026-09-30 |
| [0012](0012-event-display-text.md) | Centralize event time and date-range formatting | accepted | 2026-09-30 |
| [0013](0013-in-window-navigation.md) | Keep details, filters, and Help in the menu window | accepted | 2026-09-30 |
| [0014](0014-day-indicators.md) | Compact calendar indicators and distinguish Today from selection | accepted | 2026-09-30 |
| [0015](0015-window-height.md) | Persist adjustable window height with fixed width | accepted | 2026-09-30 |
| [0016](0016-localization-accessibility.md) | Support English, German, VoiceOver, and keyboard navigation | accepted | 2026-09-30 |
| [0017](0017-opaque-system-background.md) | Use an opaque system background for the menu | accepted | 2026-09-30 |
| [0018](0018-vector-brand-assets.md) | Use one vector cat mark with the Ice and Rust palette | accepted | 2026-09-30 |
| [0019](0019-synthetic-test-data.md) | Use isolated synthetic data for unit and UI tests | accepted | 2026-09-30 |
| [0020](0020-core-coverage-gate.md) | Require at least 95 percent coverage for each listed core file | accepted | 2026-09-30 |
| [0021](0021-project-generation.md) | Generate the checked-in Xcode project from project.yml | accepted | 2026-09-30 |
| [0022](0022-universal-build.md) | Verify arm64 and x86_64 in CI and releases | accepted | 2026-09-30 |
| [0023](0023-signed-dmg-release.md) | Distribute a signed and notarized DMG with an Applications shortcut | accepted | 2026-09-30 |
| [0024](0024-temporary-signing-keychain.md) | Keep signing material in secrets and a temporary keychain | accepted | 2026-09-30 |
| [0025](0025-documentation-screenshots.md) | Render documentation screenshots from real views and fixed fixtures | accepted | 2026-09-30 |
| [0026](0026-open-source-governance.md) | Use MIT for code and artwork with documented contribution paths | accepted | 2026-09-30 |
| [0027](0027-workflow-dependencies.md) | Pin GitHub Actions to commit SHAs and maintain them with Dependabot | accepted | 2026-09-30 |
| [0028](0028-calendar-title-decoding.md) | Decode a bounded set of entities in calendar and event titles | accepted | 2026-09-30 |
| [0029](0029-icon-action-layout.md) | Place Help in the footer and use consistent icon buttons | accepted | 2026-09-30 |
| [0030](0030-zero-duration-events.md) | Treat zero-duration timed events separately from invalid intervals | accepted | 2026-10-01 |
| [0031](0031-long-content-presentation.md) | Make complete event content and important errors readable | accepted | 2026-10-01 |
| [0032](0032-interaction-validation.md) | Validate complete keyboard, VoiceOver, and resize interactions | accepted | 2026-10-01 |
| [0033](0033-reproducible-project-generation.md) | Pin XcodeGen and reject generated-project drift | accepted | 2026-10-01 |
| [0034](0034-security-support-policy.md) | Keep security support policy aligned with published releases | accepted | 2026-10-01 |
| [0035](0035-entitlements-xml-validation.md) | Use well-formed entitlement XML and validate it independently | accepted | 2026-10-01 |
| [0036](0036-launch-at-login.md) | Offer an optional launch-at-login setting | accepted | 2026-10-01 |
| [0037](0037-manual-update-path.md) | Offer a browser-based path to release updates | superseded | 2026-10-01 |

## Using these records

- [Architecture references and validation](../ARCHITECTURE-REFERENCES.md): project sources and implementation references.
- [Implementation guide](../IMPLEMENTATION.md): behavior contracts, implementation sequence, and acceptance criteria.
- [Template](template.md): document further architecture decisions.

ADRs explain why a choice applies and what costs follow from it. The implementation guide defines behavior; source code and tests provide implementation details. Shared verification guidance lives in the architecture references rather than being repeated in every record. Start with product scope and data rules, then state management, presentation, and verification.

| [0038](0038-signed-automatic-updates.md) | Deliver signed automatic updates through Sparkle and GitHub Releases | accepted | 2026-10-01 |

## Maintenance

New decisions start as `proposed`. Explicit acceptance or established implementation changes their status to `accepted`. Give a fundamental change a new number and mark the previous record `superseded by ADR-NNNN`, linking its replacement rather than rewriting its history. Use `deprecated` for decisions that no longer apply. Editorial corrections and additional references are allowed.
