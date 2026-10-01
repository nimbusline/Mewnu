# ADR implementation validation

Date: 2026-10-01. Source baseline: `b61a7f6` plus the working-tree implementation of ADRs 0030–0037. Environment: macOS 26.6.2, Xcode 27.0 (27A266a), pinned upstream XcodeGen 2.46.0. Test data is synthetic. This record describes local verification, not a published or verified release.

## Implemented scope

| ADR | Implementation | Evidence and remaining checks |
| --- | --- | --- |
| 0030 | Timed point-event import, consistent day lookup/indexing, one-time detail formatting; reject negative and zero all-day intervals | Service, math, formatting, filter/marker tests; actual EventKit query inclusion still needs a synthetic test calendar |
| 0031 | Complete wrapping details in one scroll area, fixed close action, growing notes space, wrapping scrollable errors above footer | German long-content/error UI tests, regenerated native screenshots; manual English/German, small-display, focus, and spoken reading checks remain |
| 0032 | Keyboard shortcuts, Escape routing, interaction checklist, separate preference/layout and opt-in pointer tests | Automated navigation and UI geometry; complete Tab traversal and VoiceOver remain manual checks |
| 0033 | One exact tool pin and upstream archive checksum; install binary plus setting presets; reject tracked and untracked generated-project drift | Isolated clean/repeated generation, deliberate drift, ignored user state, and legitimate spec-change tests pass |
| 0034 | Latest stable release support policy, private reporting preserved | Latest stable release confirmed as v1.0.1 through the project release API on this date; support wording and release link checked |
| 0035 | Correct plist DOCTYPE; offline strict XML and plist checks in CI and release tooling | Original malformed declaration rejected by strict parser; current XML/plist passes with unchanged sandbox/calendar keys |
| 0036 | Native main-app login item behind injectable boundary; actual status, explicit toggle, approval/settings and recoverable failures | Fake-boundary unit/UI tests; real signed-app registration, system approval, and logout/login remain unverified |
| 0037 | Installed version and explicit latest-release browser action; manual replacement instructions | Fixed-URL and failure tests; UI uses a fake browser opener; signed replacement retaining preferences remains unverified |

Native login-item integration follows [Apple's registration API](https://developer.apple.com/documentation/servicemanagement/smappservice/register()). The generator archive is the [upstream 2.46.0 release](https://github.com/yonaskolb/XcodeGen/releases/tag/2.46.0), with the SHA-256 recorded in `scripts/toolchain/xcodegen.env`.

## Automated results

- Unit tests: 54 pass. Latest completed bundle: `build/adr-validation/UnitVerified-1790834038.xcresult`.
- Coverage gate: CalendarMath 100%, CalendarText 100%, CalendarViewModel 100%, CalendarService 97.7%, EventDisplayText 97.5%. Each listed file exceeds 95%.
- Development safeguards: `python3 scripts/tests/test-development-checks.py` passes in an isolated temporary repository. Shell syntax and XML/plist validation pass.
- Universal Release build: both x86_64 and arm64 slices verified locally. Final binary: `build/adr-validation/UniversalFinal/Build/Products/Release/Mewnu.app/Contents/MacOS/Mewnu`; both `lipo -verify_arch` checks pass.
- Full UI suite: 11 pass, one opt-in pointer test skipped, no failures. Final bundle: `build/adr-validation/UIValidated-1790834229.xcresult`. Tests scroll to clipped Help/detail controls and verify the header and footer remain reachable.
- Documentation captures: six real SwiftUI views rendered with fictional data; reviewed detail and Help captures. These are appearance evidence, not interaction evidence.

## Pointer and manual limitations

The default UI suite skips the opt-in pointer test. A local opt-in attempt synthesized the drag and stalled on the subsequent XCTest accessibility lookup and was interrupted. It does not prove resizing or persistence works. A direct native UI inspection also timed out, so there is no successful manual drag result from this session. Use `scripts/test-pointer-resize.sh` on a reliable test session or perform the checklist manually; its opt-in test has bounded execution time.

No complete keyboard Tab/Shift-Tab traversal, VoiceOver session, actual login on a separate account, real EventKit point-event query, or signed app replacement was performed. These remain required under [the interaction checklist](INTERACTION-VALIDATION.md). Signing, notarization, Gatekeeper, and remote GitHub CI were not run and must be verified separately before a release.

## Automatic updater successor

ADR-0038 supersedes the browser-only update decision in ADR-0037. Its implementation and separate local/production verification are recorded in [UPDATER-VALIDATION.md](UPDATER-VALIDATION.md).
