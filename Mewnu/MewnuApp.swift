import SwiftUI

@main
struct MewnuApp: App {
    @StateObject private var model: CalendarViewModel
    @StateObject private var windowSize: MenuWindowSize
    @StateObject private var preferences: AppPreferences

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        let service: CalendarService = isUITesting
            ? DemoCalendarService(
                access: ProcessInfo.processInfo.arguments.contains("-ui-testing-denied") ? .denied : .allowed,
                manyCalendars: ProcessInfo.processInfo.arguments.contains("-ui-testing-many-calendars"),
                longContent: ProcessInfo.processInfo.arguments.contains("-ui-testing-long-content"),
                failLoad: ProcessInfo.processInfo.arguments.contains("-ui-testing-load-error")
            )
            : EventKitCalendarService()
        let defaults: UserDefaults
        if isUITesting {
            let suite = "io.github.nimbusline.mewnu.ui-testing"
            defaults = UserDefaults(suiteName: suite)!
            if !ProcessInfo.processInfo.arguments.contains("-ui-testing-preserve-preferences") {
                defaults.removePersistentDomain(forName: suite)
            }
        } else {
            defaults = .standard
        }
        _model = StateObject(wrappedValue: CalendarViewModel(service: service, defaults: defaults))
        let windowSize = MenuWindowSize(defaults: defaults)
        if isUITesting && ProcessInfo.processInfo.arguments.contains("-ui-testing-short-window") {
            windowSize.saveHeight(MenuWindowSize.minimumHeight, maximum: MenuWindowSize.maximumHeight)
        }
        _windowSize = StateObject(wrappedValue: windowSize)
        _preferences = StateObject(wrappedValue: AppPreferences(
            system: isUITesting ? DemoAppPreferencesSystem() : NativeAppPreferencesSystem()))
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(model: model, windowSize: windowSize, preferences: preferences)
        } label: {
            Image("MenuIcon").renderingMode(.template).accessibilityLabel("Mewnu")
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
private final class DemoCalendarService: CalendarService {
    var onChange: (() -> Void)?
    let access: CalendarAccess
    let manyCalendars: Bool
    let longContent: Bool
    let failLoad: Bool
    init(access: CalendarAccess, manyCalendars: Bool, longContent: Bool, failLoad: Bool) {
        self.access = access
        self.manyCalendars = manyCalendars
        self.longContent = longContent
        self.failLoad = failLoad
    }
    func requestAccess() async -> CalendarAccess { access }
    func load(from start: Date, to end: Date) async throws -> CalendarSnapshot {
        if failLoad {
            throw NSError(domain: "Synthetic", code: 1, userInfo: [NSLocalizedDescriptionKey:
                String(repeating: "Synthetischer Ladefehler mit ausführlichem Hinweis zur Wiederherstellung. ", count: 6)
                + "Ende des Hinweises"])
        }
        let date = Date()
        if manyCalendars {
            let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
            return CalendarSnapshot(
                calendars: (0..<50).map {
                    CalendarInfo(id: "demo-\($0)", title: "Calendar \($0)", color: colors[$0 % colors.count])
                },
                events: (0..<50).map {
                    EventInfo(id: "event-\($0)", calendarID: "demo-\($0)", title: "Sample event",
                              start: date, end: date.addingTimeInterval(3600), isAllDay: false,
                              location: nil, notes: nil)
                }
            )
        }
        return CalendarSnapshot(
            calendars: [
                CalendarInfo(id: "demo", title: "Demo", color: .orange),
                CalendarInfo(id: "long", title: "A much longer sample calendar", color: .blue),
                CalendarInfo(id: "third", title: "Third", color: .green)
            ],
            events: [EventInfo(id: "demo-1", calendarID: "demo", title: longContent ? String(repeating: "Langfristige Projektabstimmung mit allen Beteiligten ", count: 8) : "Sample event", start: date,
                               end: date.addingTimeInterval(3600), isAllDay: false,
                               location: longContent ? "Konferenzzentrum\n" + String(repeating: "Langer Standort mit Anreisebeschreibung ", count: 8) : "Example location",
                               notes: longContent ? String(repeating: "Ausführliche synthetische Besprechungsnotizen.\n\n", count: 40) + String(repeating: "Synthetisch", count: 80) + "\nEnde der Notizen" : "Example notes")]
        )
    }
}
