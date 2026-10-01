import AppKit
import ServiceManagement
import SwiftUI

enum LoginItemState: Equatable {
    case disabled, enabled, requiresApproval, unavailable

    var isRegistered: Bool { self == .enabled || self == .requiresApproval }

    var message: String {
        switch self {
        case .disabled: String(localized: "Launch at login is off.")
        case .enabled: String(localized: "Launch at login is on.")
        case .requiresApproval: String(localized: "Approve Mewnu in System Settings → General → Login Items & Extensions.")
        case .unavailable: String(localized: "Launch at login is unavailable. Install Mewnu in Applications and try again.")
        }
    }
}

@MainActor
protocol AppPreferencesSystem {
    var loginItemState: LoginItemState { get }
    func setLaunchAtLogin(_ enabled: Bool) throws
    func openLoginItemSettings()
    func openURL(_ url: URL) -> Bool
}

struct NativeAppPreferencesSystem: AppPreferencesSystem {
    var loginItemState: LoginItemState {
        switch SMAppService.mainApp.status {
        case .notRegistered: .disabled
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        case .notFound: .unavailable
        @unknown default: .unavailable
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) throws {
        if enabled { try SMAppService.mainApp.register() }
        else { try SMAppService.mainApp.unregister() }
    }

    func openLoginItemSettings() { SMAppService.openSystemSettingsLoginItems() }
    func openURL(_ url: URL) -> Bool { NSWorkspace.shared.open(url) }
}

// UI tests and documentation never change the user's login items or open a browser.
@MainActor
final class DemoAppPreferencesSystem: AppPreferencesSystem {
    var loginItemState: LoginItemState = .disabled
    func setLaunchAtLogin(_ enabled: Bool) { loginItemState = enabled ? .enabled : .disabled }
    func openLoginItemSettings() {}
    func openURL(_ url: URL) -> Bool { true }
}

@MainActor
final class AppPreferences: ObservableObject {
    static let releasesURL = URL(string: "https://github.com/nimbusline/Mewnu/releases/latest")!
    @Published private(set) var loginItemState: LoginItemState
    @Published private(set) var errorMessage: String?
    let installedVersion: String
    private let system: AppPreferencesSystem

    init(system: AppPreferencesSystem? = nil, bundle: Bundle = .main) {
        let system = system ?? NativeAppPreferencesSystem()
        self.system = system
        self.loginItemState = system.loginItemState
        self.installedVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    func refresh() { loginItemState = system.loginItemState }

    func setLaunchAtLogin(_ enabled: Bool) {
        refresh()
        guard enabled != loginItemState.isRegistered else { return }
        do {
            try system.setLaunchAtLogin(enabled)
            errorMessage = nil
        } catch {
            errorMessage = String(localized: "Could not change launch at login. Check Login Items in System Settings and try again.")
        }
        refresh()
    }

    func openLoginItemSettings() { system.openLoginItemSettings() }

    func openLatestRelease() {
        errorMessage = system.openURL(Self.releasesURL) ? nil
            : String(localized: "Could not open the release page. Open github.com/nimbusline/Mewnu/releases in your browser.")
    }
}
