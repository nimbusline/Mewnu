import XCTest
@testable import Mewnu

@MainActor
final class AppPreferencesTests: XCTestCase {
    private final class FakeSystem: AppPreferencesSystem {
        var loginItemState: LoginItemState = .disabled
        var requested: [Bool] = []
        var registrationError = false
        var needsApproval = false
        var openedURLs: [URL] = []
        var canOpen = true
        var settingsCount = 0
        func setLaunchAtLogin(_ enabled: Bool) throws {
            requested.append(enabled)
            if registrationError { throw NSError(domain: "Synthetic", code: 1) }
            loginItemState = enabled ? (needsApproval ? .requiresApproval : .enabled) : .disabled
        }
        func openLoginItemSettings() { settingsCount += 1 }
        func openURL(_ url: URL) -> Bool { openedURLs.append(url); return canOpen }
    }

    func testDefaultDoesNotRegisterOrOpenReleasesAndUsesSystemState() {
        let system = FakeSystem()
        let model = AppPreferences(system: system)
        XCTAssertEqual(model.loginItemState, .disabled)
        XCTAssertTrue(system.requested.isEmpty)
        XCTAssertTrue(system.openedURLs.isEmpty)
        system.loginItemState = .enabled
        model.refresh()
        XCTAssertEqual(model.loginItemState, .enabled)
        system.loginItemState = .unavailable
        model.refresh()
        XCTAssertEqual(model.loginItemState, .unavailable)
    }

    func testRegisterDisableAndExternalStateChanges() {
        let system = FakeSystem()
        let model = AppPreferences(system: system)
        model.setLaunchAtLogin(true)
        XCTAssertEqual(model.loginItemState, .enabled)
        model.setLaunchAtLogin(true)
        XCTAssertEqual(system.requested, [true])
        system.loginItemState = .disabled
        model.refresh()
        XCTAssertEqual(model.loginItemState, .disabled)
        model.setLaunchAtLogin(true)
        model.setLaunchAtLogin(false)
        XCTAssertEqual(system.requested, [true, true, false])
        XCTAssertEqual(model.loginItemState, .disabled)
    }

    func testApprovalAndFailuresRemainRecoverable() {
        let system = FakeSystem()
        system.needsApproval = true
        let model = AppPreferences(system: system)
        model.setLaunchAtLogin(true)
        XCTAssertEqual(model.loginItemState, .requiresApproval)
        XCTAssertTrue(model.loginItemState.isRegistered)
        model.openLoginItemSettings()
        XCTAssertEqual(system.settingsCount, 1)
        system.registrationError = true
        model.setLaunchAtLogin(false)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(model.loginItemState, .requiresApproval)
        system.registrationError = false
        model.setLaunchAtLogin(false)
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(model.loginItemState, .disabled)
    }

    func testReleaseActionUsesFixedURLAndReportsBrowserFailure() {
        let system = FakeSystem()
        let model = AppPreferences(system: system)
        XCTAssertEqual(model.installedVersion, Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")
        system.canOpen = false
        model.openLatestRelease()
        XCTAssertEqual(system.openedURLs, [URL(string: "https://github.com/nimbusline/Mewnu/releases/latest")!])
        XCTAssertNotNil(model.errorMessage)
        system.canOpen = true
        model.openLatestRelease()
        XCTAssertNil(model.errorMessage)
    }
}
