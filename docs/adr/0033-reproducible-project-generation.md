# ADR-0033: Pin XcodeGen and reject generated-project drift

- **Status:** accepted
- **Decision date:** 2026-10-01
- **Documented:** 2026-10-01
- **Implementation:** implemented; automated evidence and remaining manual checks are recorded in [implementation validation](../ADR-IMPLEMENTATION-VALIDATION.md).

## Context

Workflow Actions are pinned to commit SHAs, but the reviewed workflows installed XcodeGen through unversioned Homebrew installation. A generator update can change the checked-in project without a change to project.yml. At review time, CI generated the project but did not reject differences from the committed output. This extends [ADR-0021](0021-project-generation.md) and [ADR-0027](0027-workflow-dependencies.md).

## Decision

Use one exact, repository-controlled XcodeGen version shared by CI, release tooling, and documented local generation. Select and validate the initial version, at least 2.46.0, against the existing project during implementation. The initial pin is XcodeGen 2.46.0, with its upstream archive checksum recorded in the repository. Install that exact release from a fixed artifact with a verified checksum and check the reported version; do not silently fall back to Homebrew's latest version.

After generation in a clean checkout, fail CI and release validation if any tracked project output differs or new project output is untracked. Exclude ignored, user-specific Xcode state. Review generator upgrades together with regenerated output and relevant build/test results.

## Alternatives

- **Continue unversioned Homebrew installation.** Simple setup, but output depends on the available formula version.
- **Commit only project.yml.** Avoids checking generated drift, but removes the directly openable checked-in project required by ADR-0021.

## Consequences

Generator updates become explicit and drift is detected before distribution. Artifact checksums and tool updates need maintenance. This improves project-generation reproducibility; it does not pin macOS/Xcode or guarantee byte-identical signed releases.

## Implementation and validation

Check generation from a clean checkout and repeat it to establish stable output. Deliberately change a generated setting and add an untracked generated file to confirm rejection. Verify a legitimate project.yml change passes after regeneration. Keep universal build, unit coverage, and UI checks. Synchronize README, CONTRIBUTING, AGENTS guidance, and RELEASING requirements when adopting the pin.

References: [CI](../../.github/workflows/ci.yml), [release workflow](../../.github/workflows/release.yml), [release script](../../scripts/release.sh), [project.yml](../../project.yml), [generated project](../../Mewnu.xcodeproj/project.pbxproj).
