# ADR-0026: Use MIT for code and artwork with documented contribution paths

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

The project should support open-source use and provide guidance for users and developers.

## Decision

License code and artwork under MIT. Separate usage and development guidance in README. Define contribution rules in CONTRIBUTING and distribution in RELEASING. Use issue/PR templates and a Code of Conduct. Handle security reports privately according to SECURITY.md. Exclude calendar content, secrets, and local settings from versioned examples.

## Alternatives

- Give code and artwork separate licenses: supports different reuse policies, but requires maintaining and explaining their boundaries. One MIT license matches a shared reuse policy.
- Keep contribution and release guidance in a single README: offers one entry point, but mixes user instructions with maintenance procedures. Dedicated guides keep each workflow easier to find and update.

## Consequences

One license covers code and artwork, and documented paths make contribution and security handling predictable. Maintainers must keep templates and guidance aligned with the release process and respond through those channels. Shared licensing also means artwork follows the same reuse policy as code rather than a separate brand-specific policy.

## Implementation and validation

Code and artwork have an explicit MIT license. Contribution, security, and release paths are documented, and examples contain only synthetic calendar data.

Implementation references:

- [LICENSE](../../LICENSE)
- [README.md](../../README.md)
- [CONTRIBUTING.md](../../CONTRIBUTING.md)
- [SECURITY.md](../../SECURITY.md)
- [CODE_OF_CONDUCT.md](../../CODE_OF_CONDUCT.md)
- [.github/PULL_REQUEST_TEMPLATE.md](../../.github/PULL_REQUEST_TEMPLATE.md)
