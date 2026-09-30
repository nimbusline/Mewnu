# ADR-0027: Pin GitHub Actions to commit SHAs and maintain them with Dependabot

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

Builds depend on external Actions and development tools even without app runtime libraries. These dependencies need reviewable updates.

## Decision

Pin workflow Actions to full commit SHAs with readable version comments. Check GitHub Actions weekly through Dependabot. Run normal CI's unit tests, coverage gate, universal build, and UI tests sequentially. Use a separate release workflow.

## Alternatives

- Use version tags with Dependabot updates: readable references and automated proposals, but a tag can change without a repository diff. Full commit SHAs fix the revision being reviewed.
- Pin SHAs and review updates on a manual schedule: retains explicit revisions, but relies on maintainers to discover available updates. Weekly Dependabot proposals provide a regular review queue.

## Consequences

Pinned Action revisions make workflow changes explicit and reviewable. Weekly update proposals create recurring review and CI work; a pin stays unchanged until an update is merged. Sequential checks use one ordered workflow but take longer than parallel jobs. Action pins do not pin every tool installed by the workflow.

## Implementation and validation

Actions use complete commit SHAs and Dependabot checks weekly. Relevant CI checks pass after updates.

Implementation references:

- [.github/workflows/ci.yml](../../.github/workflows/ci.yml)
- [.github/workflows/release.yml](../../.github/workflows/release.yml)
- [.github/dependabot.yml](../../.github/dependabot.yml)
