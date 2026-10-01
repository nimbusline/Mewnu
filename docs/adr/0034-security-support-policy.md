# ADR-0034: Keep security support policy aligned with published releases

- **Status:** accepted
- **Decision date:** 2026-10-01
- **Documented:** 2026-10-01
- **Implementation:** implemented; automated evidence and remaining manual checks are recorded in [implementation validation](../ADR-IMPLEMENTATION-VALIDATION.md).

## Context

At review time, SECURITY.md contained prerelease wording saying there is no published release, while README directs users to release downloads. The review identifies this wording as stale. Support scope is a maintenance commitment and must be distinguished from whether an individual release passed its technical checks. This supplements [ADR-0026](0026-open-source-governance.md).

## Decision

Replace the prerelease paragraph with a policy supporting the latest stable published release and welcoming reports against main. Link to GitHub Releases rather than hard-coding a version that becomes stale after publication. Make older-version support explicit if maintainers later choose to provide it. Review the policy as part of each release and retain private reporting and synthetic-data requirements.

## Alternatives

- **Maintain a version support table.** Allows multiple supported branches, but adds upkeep for a project supporting one stable release.
- **Accept reports without identifying support scope.** Low maintenance, but leaves users unsure which versions receive fixes.

## Consequences

Users can identify the supported release without waiting for a documentation version bump. Supporting only the latest stable version can require an upgrade before a fix is available. This policy does not establish response deadlines or prove release quality.

## Implementation and validation

When updating the wording, confirm the published stable release. Acceptance establishes the support commitment for the latest stable release. Check the release link and private reporting instructions. Remove the obsolete no-release assertion. Record publication and release verification separately; this documentation error alone does not establish a broken release.

References: [Security policy](../../SECURITY.md), [README](../../README.md), [release guide](../../RELEASING.md), [reported revision](https://github.com/nimbusline/Mewnu/blob/b61a7f61b8740779dcd920c1dc972469076dd686/SECURITY.md#L5).
