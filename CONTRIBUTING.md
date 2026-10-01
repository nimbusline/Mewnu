# Contributing

Thanks for helping Mewnu. Please open an issue to discuss significant behavior or design changes before implementing them. Small bug fixes and accessibility improvements are welcome as pull requests.

Use the bug or feature issue template so reports include enough context. For a security or privacy issue, follow [SECURITY.md](SECURITY.md) instead of opening a public bug report. Participation follows our [Code of Conduct](CODE_OF_CONDUCT.md).

1. Use Xcode 27 or newer and XcodeGen 2.46.0 (pinned). Install it with `scripts/install-xcodegen.sh`, then run `scripts/generate-project.sh` after changing sources or `project.yml`. Include generated changes; CI rejects project drift.
2. Keep calendar data local and read-only. Avoid logging event titles, notes, locations, or account names.
3. Add focused tests for behavior changes. Run the unit and UI tests before submitting a pull request.
4. Keep the German and English strings in sync and follow [the interaction checklist](docs/INTERACTION-VALIDATION.md) for keyboard, VoiceOver, and actual resize checks.
5. Include screenshots only with sample data, never personal calendar information.

By contributing, you agree that your contribution is distributed under the repository's MIT license.

Updater changes must retain pinned Sparkle/package versions, signed feed/archive verification, and sandbox permissions. Install the signing tools with `scripts/install-sparkle-tools.sh` and run `python3 scripts/tests/test-update-feed.py`; it uses an ephemeral synthetic key without touching the real signing Keychain. UI tests and documentation use the demo updater. See ADR-0038 and RELEASING.md for the production installer checks.
