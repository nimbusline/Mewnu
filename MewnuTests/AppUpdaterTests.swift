import XCTest
@testable import Mewnu

@MainActor
final class AppUpdaterTests: XCTestCase {
    func testDefaultsAndExplicitManualCheck() {
        let driver = DemoUpdateDriver()
        let updater = AppUpdater(driver: driver)
        XCTAssertFalse(updater.automaticallyChecksForUpdates)
        XCTAssertFalse(updater.automaticallyInstallsUpdates)
        XCTAssertEqual(driver.checkCount, 0)
        updater.checkForUpdates()
        XCTAssertEqual(driver.checkCount, 1)
        driver.canCheckForUpdates = false
        driver.onChange?()
        XCTAssertFalse(updater.canCheckForUpdates)
        updater.checkForUpdates()
        XCTAssertEqual(driver.checkCount, 1)
    }

    func testAutomaticInstallationRequiresChecksAndDisablingClearsIt() {
        let driver = DemoUpdateDriver()
        let updater = AppUpdater(driver: driver)
        updater.setAutomaticInstallation(true)
        XCTAssertFalse(driver.automaticallyDownloadsUpdates)
        updater.setAutomaticChecks(true)
        updater.setAutomaticInstallation(true)
        XCTAssertTrue(updater.automaticallyChecksForUpdates)
        XCTAssertTrue(updater.automaticallyInstallsUpdates)
        updater.setAutomaticChecks(false)
        XCTAssertFalse(driver.automaticallyDownloadsUpdates)
        XCTAssertFalse(updater.automaticallyInstallsUpdates)
        XCTAssertFalse(updater.automaticallyChecksForUpdates)
        updater.setAutomaticChecks(true)
        XCTAssertFalse(updater.automaticallyInstallsUpdates)
    }

    func testRestoresDriverPreferencesWithoutResettingThemAndObservesChanges() {
        let driver = DemoUpdateDriver()
        driver.automaticallyChecksForUpdates = true
        driver.automaticallyDownloadsUpdates = true
        let updater = AppUpdater(driver: driver)
        XCTAssertTrue(updater.automaticallyInstallsUpdates)
        XCTAssertTrue(updater.automaticallyChecksForUpdates)
        driver.automaticallyDownloadsUpdates = false
        driver.onChange?()
        XCTAssertFalse(updater.automaticallyInstallsUpdates)
        XCTAssertEqual(driver.checkCount, 0)
    }
}
