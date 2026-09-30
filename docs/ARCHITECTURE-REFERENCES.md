# Architecture references and validation

The [ADRs](adr/README.md) define architecture decisions. This overview maps them to code, tests, and project documentation as implementation references. The [implementation guide](IMPLEMENTATION.md) adds behavior rules and acceptance criteria.

Documentation edition: 2026-09-30. Technical references correspond to project revision `2ac1298`. The ADRs describe applicable decisions as guidance; dates and status do not establish a historical order of decisions and implementation.

## Application and repository

| Area | Implementation references | Related ADRs |
| --- | --- | --- |
| Entry point and configuration | [MewnuApp](../Mewnu/MewnuApp.swift), [Info.plist](../Mewnu/Info.plist), [Entitlements](../Mewnu/Mewnu.entitlements), [project.yml](../project.yml), generated project and scheme | 0001–0003, 0019, 0021–0022 |
| Calendar data | [Service](../Mewnu/Core/CalendarService.swift), [ViewModel](../Mewnu/Core/CalendarViewModel.swift), [Models](../Mewnu/Core/Models.swift), [Math](../Mewnu/Core/CalendarMath.swift), [Text](../Mewnu/Core/CalendarText.swift), [DisplayText](../Mewnu/Core/EventDisplayText.swift), [Workspace](../Mewnu/Core/CalendarWorkspace.swift), and [MenuWindowSize](../Mewnu/Core/MenuWindowSize.swift) | 0003–0012, 0015, 0028 |
| Presentation | [ContentView](../Mewnu/Views/ContentView.swift), [MonthGridView](../Mewnu/Views/MonthGridView.swift), English and German localization files and assets | 0013–0018, [0029](adr/0029-icon-action-layout.md) |
| Tests | All seven files in [MewnuTests](../MewnuTests), [MewnuUITests](../MewnuUITests/MewnuUITests.swift), [coverage check](../scripts/check-unit-coverage.py) | 0019–0020 and the corresponding domain ADRs |
| Build and distribution | [CI](../.github/workflows/ci.yml), [release workflow](../.github/workflows/release.yml), [release script](../scripts/release.sh), [signing wrapper](../scripts/ci-signed-release.sh), [Dependabot](../.github/dependabot.yml) | 0021–0024, 0027 |
| Brand and screenshots | [Brand guide](../Brand/README.md), three SVG originals, asset configuration, [asset generator](../scripts/generate-brand-assets.py), [screenshot renderer](../scripts/documentation-screenshots.swift), [capture script](../scripts/capture-screenshots.sh), [screenshot guide](SCREENSHOTS.md) | 0018, 0025 |
| Project contract | [README](../README.md), [CONTRIBUTING](../CONTRIBUTING.md), [RELEASING](../RELEASING.md), [MIT license](../LICENSE), [SECURITY](../SECURITY.md), [Code of Conduct](../CODE_OF_CONDUCT.md), issue/PR templates, and .gitignore | 0001, 0026–0027 |

Linked tests provide executable validation. Collect test results and manual verification for the implementation or release revision being assessed.
