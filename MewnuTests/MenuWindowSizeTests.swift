import XCTest
@testable import Mewnu

@MainActor
final class MenuWindowSizeTests: XCTestCase {
    func testDefaultAndSavedHeightSurviveRecreation() {
        let suite = "MenuWindowSizeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let size = MenuWindowSize(defaults: defaults)
        XCTAssertEqual(size.height(maximum: 900), 620)
        size.saveHeight(740, maximum: 900)
        XCTAssertEqual(size.height(maximum: 900), 740)
        XCTAssertEqual(MenuWindowSize(defaults: defaults).height(maximum: 900), 740)
    }

    func testHeightIsClampedToScreenAndAllowedRange() {
        let suite = "MenuWindowSizeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let size = MenuWindowSize(defaults: defaults)
        size.saveHeight(2_000, maximum: 800)
        XCTAssertEqual(size.height(maximum: 800), 800)
        XCTAssertEqual(size.height(maximum: 600), 600)
        XCTAssertEqual(size.height(maximum: 900), 800)
        size.saveHeight(100, maximum: 900)
        XCTAssertEqual(size.height(maximum: 900), 500)
        XCTAssertEqual(MenuWindowSize(defaults: defaults).height(maximum: 900), 500)
    }

    func testInvalidPreferenceFallsBackToDefault() {
        let suite = "MenuWindowSizeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        defaults.set(Double.nan, forKey: "menuWindowHeight")
        XCTAssertEqual(MenuWindowSize(defaults: defaults).height(maximum: 900), 620)
        defaults.set(Double.infinity, forKey: "menuWindowHeight")
        XCTAssertEqual(MenuWindowSize(defaults: defaults).height(maximum: 580), 580)
    }
}
