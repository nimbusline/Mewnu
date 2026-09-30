# ADR-0021: Generate the checked-in Xcode project from project.yml

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

Targets, settings, and test schemes should be readable in version control while the project remains directly openable in Xcode.

## Decision

Use XcodeGen to generate Mewnu.xcodeproj from project.yml and commit both. Regenerate after source or project-setting changes and include the generated diff. Require Xcode 27+ and XcodeGen 2.46.0 or later.

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
