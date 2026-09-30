# ADR-0024: Keep signing material in secrets and a temporary keychain

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

Signing and notarization require private credentials. Neither the repository nor test artifacts may contain them.

## Decision

Provide five named GitHub release secrets. The wrapper imports the P12 into a temporary keychain with a random password, deletes the P12, stores a notary profile, unsets certificate/password variables, and cleans up through traps. Disable shell tracing. Use contents:read for ordinary jobs and contents:write only for publishing. Checkout does not persist Git credentials.

## Alternatives

- Sign releases locally using a controlled development keychain: keeps signing credentials out of CI, but makes tag releases depend on an available signing machine and manual handoff. CI signing supports the automated release workflow.
- Use a persistent keychain on a dedicated runner: reduces repeated setup, but requires runner lifecycle and credential cleanup management. A temporary keychain fits isolated release jobs.

## Consequences

Temporary keychains bound the lifetime of signing material on the runner and support automated tag releases. Each run repeats credential import and cleanup, and the wrapper must restore the keychain environment on success and failure. Repository secrets and signing identities still need access control, rotation, and renewal; cleanup cannot replace those operational responsibilities.

## Implementation and validation

The wrapper checks required secrets, uses a temporary keychain, and cleans up on errors. Logs and artifacts contain no private keys or passwords.

Implementation references:

- [scripts/ci-signed-release.sh](../../scripts/ci-signed-release.sh)
- [.github/workflows/release.yml](../../.github/workflows/release.yml)
- [RELEASING.md](../../RELEASING.md)
