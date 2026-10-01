# ADR-0035: Use well-formed entitlement XML and validate it independently

- **Status:** accepted
- **Decision date:** 2026-10-01
- **Documented:** 2026-10-01
- **Implementation:** implemented; automated evidence and remaining manual checks are recorded in [implementation validation](../ADR-IMPLEMENTATION-VALIDATION.md).

## Context

At the reviewed baseline, Mewnu.entitlements had a malformed PUBLIC DOCTYPE with an extra quoted identifier. A permissive plist reader or successful macOS pipeline does not establish strict XML validity. The review reports a successful pipeline, so this repository defect alone is insufficient evidence of a broken distributed release.

## Decision

Correct the declaration to the conventional plist PUBLIC identifier and single system identifier, removing the extra identifier. Preserve the sandbox and calendar entitlement keys and values. Add independent strict XML and plist validation before build/signing in CI and release validation.

## Alternatives

- **Remove the DOCTYPE.** Can produce well-formed XML and avoid a DTD reference, but the conventional plist declaration keeps familiar Apple file structure with a minimal correction.
- **Rely solely on build success.** Avoids another check, but leaves parser-dependent acceptance and does not directly verify XML well-formedness.

## Consequences

The source can be consumed by stricter XML tooling without changing requested permissions. Validation adds a small tool dependency. XML parsing must not require fetching the external DTD during CI.

## Implementation and validation

Require offline strict XML parsing and `plutil -lint` to pass, and confirm the original malformed declaration fails the strict check. Compare parsed entitlement keys and values before and after the correction. Build with the corrected file; inspect signed entitlements when verifying a release. Keep notarization, Gatekeeper assessment, and CI evidence separate from XML validity, following [ADR-0023](0023-signed-dmg-release.md).

References: [Entitlements](../../Mewnu/Mewnu.entitlements), [CI](../../.github/workflows/ci.yml), [release workflow](../../.github/workflows/release.yml), [reported revision](https://github.com/nimbusline/Mewnu/blob/b61a7f61b8740779dcd920c1dc972469076dd686/Mewnu/Mewnu.entitlements#L2).
