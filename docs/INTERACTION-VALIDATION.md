# Interaction validation

[ADR-0032](adr/0032-interaction-validation.md) requires automated and manual evidence to be recorded separately. Use synthetic calendars, never personal calendar data. Run UI tests sequentially in one macOS session.

## Record for each relevant UI change and release

Record the source revision (or base revision plus working-tree changes), macOS and Xcode versions, language, appearance, display size, input method, expected behavior, observed behavior, and pass/fail/unverified result. Include automated result-bundle paths separately. Do not mark unperformed checks as passed.

## Keyboard only

Enable macOS Keyboard navigation for the manual session and record that setting. Open the menu through the menu bar using the keyboard. Traverse forward with Tab and backward with Shift-Tab; activate controls with Space/Return. Check visible focus and absence of traps in the overview, all 42 day cells, agenda, filter list, details, Help, and permission recovery. Select a day and event, read details, toggle a calendar, and return using Escape. Verify Today, month, filter, and Help shortcuts. Confirm Help, calendar, and quit actions remain reachable at minimum height and with a long synthetic error. Exercise Quit only in the test app.

Automated keyboard shortcut checks cover month navigation, Today, filters, Help, and Escape. They do not establish complete Tab traversal or visible focus quality.

## VoiceOver

In English and German, navigate from the menu bar through each content state. Check meaningful names, date/Today/selection state, calendar names, event title/time, checkbox state, reading order, and decorative-element exclusion. Read the entire long title, multiline location, notes, and error. Verify close/back actions, permission recovery, and status text for login approval and failures. Adjust window height through the accessibility action in both directions and confirm geometry and persistence. Record actual observations; accessibility-tree labels alone do not validate spoken interaction.

## Pointer resizing and content

Drag the bottom handle larger and smaller. Check live preview, saving only on release, bounds, relaunch persistence, and footer/handle geometry. Repeat near the available display-height limit and on a small display. Check long German and English titles, locations, unbroken strings, multiline notes, and error text at minimum and expanded heights, in light and dark appearance. Scroll to the end; ensure close/back and footer actions stay reachable.

The saved-height UI test checks preference/layout behavior. The opt-in `testPointerDragSavesHeightAcrossRelaunch` sends a real XCTest pointer gesture; run `scripts/test-pointer-resize.sh` on a reliable local session. The script sets `MEWNU_TEST_POINTER_DRAG=1` in the generated test-run environment and bounds test execution time. It is skipped by default because some CI sessions do not deliver the gesture. A skipped gesture check requires manual verification and is not a pass.

## Test-account integration

Use a separate macOS test account and signed app installed in Applications. Enable/disable launch at login, approve it if macOS requests it, log out/in, and confirm actual launch and disabled behavior. Change registration in System Settings and return to Mewnu; the displayed state must update. Check denied registration and recovery. Replace the app with a signed release using the documented manual update steps and verify filters/window height survive. Check EventKit point-event query inclusion, permission changes, synchronization, and recurrence exceptions on a synthetic test calendar.

## Current change evidence

Implementation of ADRs 0030–0037 is dated 2026-10-01. Automated results and remaining manual checks are recorded in [ADR implementation validation](ADR-IMPLEMENTATION-VALIDATION.md). No actual login, VoiceOver session, or signed replacement is inferred from unit/UI test success.

For ADR-0038, check the localized manual-update action, automatic-check/install toggles, disabled installation until checks are enabled, and clearing installation when checks are disabled. Use synthetic fixtures for UI checks. On a separate account, test an actual signed older/newer pair, unavailable network/feed, update prompts, installation and relaunch, retained preferences, VoiceOver, and keyboard focus.
