import AppKit

@MainActor
protocol CalendarWorkspace {
    func calendarApplicationURL() -> URL?
    func openApplication(at url: URL, completion: @escaping (Error?) -> Void)
    func openPrivacySettings()
}

struct SystemCalendarWorkspace: CalendarWorkspace {
    func calendarApplicationURL() -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal")
    }

    func openApplication(at url: URL, completion: @escaping (Error?) -> Void) {
        NSWorkspace.shared.openApplication(at: url, configuration: .init()) { _, error in
            completion(error)
        }
    }

    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"),
           NSWorkspace.shared.open(url) { return }
        if let settings = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.systempreferences") {
            NSWorkspace.shared.open(settings)
        }
    }
}
