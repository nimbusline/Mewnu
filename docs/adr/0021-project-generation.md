# ADR-0021: Generate the checked-in Xcode project from project.yml

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

Targets, settings, and test schemes should be readable in version control while the project remains directly openable in Xcode.

## Decision

Use XcodeGen to generate Mewnu.xcodeproj from project.yml and commit both. Regenerate after source or project-setting changes and include the generated diff. Require Xcode 27+ and XcodeGen 2.46.0 or later.

**Extension accepted 2026-10-01:** [ADR-0033](0033-reproducible-project-generation.md) requires an exact repository-controlled XcodeGen version, at least 2.46.0, and checks for generated-project drift. The earlier minimum-version rule alone is no longer sufficient. The implemented initial pin is 2.46.0; see [implementation validation](../ADR-IMPLEMENTATION-VALIDATION.md) for generation and drift-check evidence.

## Alternatives

- Maintain only pbxproj manually: no generator, but less readable project changes.
- Commit only generator YAML: less generated history, but no ready-to-open Xcode project.

## Consequences

YAML keeps project changes readable while the checked-in project opens directly in Xcode. Maintaining both requires regeneration and review of generated diffs. Manual project edits can be overwritten, and generator upgrades may change project output even without a product change.

## Implementation and validation

xcodegen generate produces app, unit-test, and UI-test targets. Commit generated changes alongside their YAML source.

Implementation references:

- [project.yml](../../project.yml)
- [Mewnu.xcodeproj/project.pbxproj](../../Mewnu.xcodeproj/project.pbxproj)
- [README.md](../../README.md)
- [.github/workflows/ci.yml](../../.github/workflows/ci.yml)
