# ADR-0020: Require at least 95 percent coverage for each listed core file

- **Status:** accepted
- **Documented:** 2026-09-30

## Context

Calendar logic needs high, verifiable unit coverage. A project-wide percentage can hide weak core coverage behind rendering tests.

## Decision

Normal CI measures unit coverage and requires at least 95 percent for each of CalendarMath.swift, CalendarText.swift, CalendarViewModel.swift, CalendarService.swift, and EventDisplayText.swift. Missing files or the Mewnu.app coverage target fail the check. UI and manual integration checks complement core tests.

## Alternatives

- Require 95 percent across the whole project: simpler reporting, but permits poorly covered core files to be masked by other modules. Per-file checks protect each listed boundary.
- Require 100 percent for every listed core file alongside integration checks: exercises more lines, but adds test maintenance for the final few paths. A 95 percent floor leaves room for targeted review without treating line execution as a complete quality measure.

## Consequences

Per-file thresholds prevent strong coverage in one module from hiding weak coverage in another. Changes to the listed files may require additional tests to pass CI, and adding a core file requires an explicit update to the gate. Line coverage measures executed lines, so assertions, failure cases, UI behavior, and real integration still need separate review.

## Implementation and validation

The check fails below 95 percent in any listed file or when data is missing. UI and integration tests remain separate evidence.

Implementation references:

- [scripts/check-unit-coverage.py](../../scripts/check-unit-coverage.py)
- [.github/workflows/ci.yml](../../.github/workflows/ci.yml)
- [scripts/release.sh](../../scripts/release.sh)
