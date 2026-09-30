import SwiftUI

@main
struct MewnuApp: App {
    @StateObject private var model: CalendarViewModel
    @StateObject private var windowSize: MenuWindowSize

    init() {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        let service: CalendarService = isUITesting
            ? DemoCalendarService(
                access: ProcessInfo.processInfo.arguments.contains("-ui-testing-denied") ? .denied : .allowed,
                manyCalendars: ProcessInfo.processInfo.arguments.contains("-ui-testing-many-calendars")
            )
            : EventKitCalendarService()
        let defaults: UserDefaults
        if isUITesting {
            let suite = "io.github.nimbusline.mewnu.ui-testing"
            defaults = UserDefaults(suiteName: suite)!
            defaults.removePersistentDomain(forName: suite)
        } else {
            defaults = .standard
        }
        _model = StateObject(wrappedValue: CalendarViewModel(service: service, defaults: defaults))
        let windowSize = MenuWindowSize(defaults: defaults)
        if isUITesting && ProcessInfo.processInfo.arguments.contains("-ui-testing-short-window") {
            windowSize.saveHeight(MenuWindowSize.minimumHeight, maximum: MenuWindowSize.maximumHeight)
        }
        _windowSize = StateObject(wrappedValue: windowSize)
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(model: model, windowSize: windowSize)
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
    init(access: CalendarAccess, manyCalendars: Bool) {
        self.access = access
        self.manyCalendars = manyCalendars
    }
    func requestAccess() async -> CalendarAccess { access }
    func load(from start: Date, to end: Date) async throws -> CalendarSnapshot {
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
            events: [EventInfo(id: "demo-1", calendarID: "demo", title: "Sample event", start: date,
                               end: date.addingTimeInterval(3600), isAllDay: false,
                               location: "Example location", notes: "Example notes")]
        )
    }
}
