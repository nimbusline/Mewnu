# ADR-0022: Verify arm64 and x86_64 in CI and releases

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

The app must support Apple silicon and Intel. A successful build on an ARM host does not establish both architectures.

## Decision

Build CI and release binaries with ARCHS='arm64 x86_64' and ONLY_ACTIVE_ARCH=NO. Verify each slice separately with lipo -verify_arch. Distribute the same universal app in one download.

## Alternatives

- Build only for the host architecture: faster, but incomplete platform support.
- Provide separate ARM and Intel downloads: smaller files, but more artifact management and user choices.

## Consequences

One download removes the need to choose a processor-specific package. Two slices increase binary size and build work. Slice checks establish that both architectures are present; they do not establish execution on both kinds of Mac, so installation and runtime checks remain distinct verification tasks.

## Implementation and validation

Release builds contain both architectures and pass lipo -verify_arch for each. Verify execution and installation separately.

Implementation references:

- [project.yml](../../project.yml)
- [.github/workflows/ci.yml](../../.github/workflows/ci.yml)
- [scripts/release.sh](../../scripts/release.sh)
