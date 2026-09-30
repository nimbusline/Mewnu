import AppKit
import SwiftUI

private final class DocumentationWindow: NSWindow {
    // Render text and native controls at 2× even on a non-Retina display.
    override var backingScaleFactor: CGFloat { 2 }
}

// Documentation-only fixtures. This executable never instantiates
// EventKitCalendarService and never reads the user's calendar or defaults.
@MainActor
private final class DocumentationCalendarService: CalendarService {
    var onChange: (() -> Void)?
    let access: CalendarAccess
    let snapshot: CalendarSnapshot

    init(access: CalendarAccess, calendar: Calendar) {
        self.access = access
        func date(_ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 9, day: day,
                                               hour: hour, minute: minute))!
        }
        func event(_ id: String, _ calendarID: String, _ title: String,
                   _ start: Date, _ end: Date, allDay: Bool = false,
                   location: String? = nil, notes: String? = nil) -> EventInfo {
            EventInfo(id: id, calendarID: calendarID, title: title, start: start,
                      end: end, isAllDay: allDay, location: location, notes: notes)
        }
        snapshot = CalendarSnapshot(
            calendars: [
                CalendarInfo(id: "work", title: "Work", color: .blue),
                CalendarInfo(id: "personal", title: "Personal", color: .orange),
                CalendarInfo(id: "family", title: "Family", color: .purple),
                CalendarInfo(id: "holidays", title: "Holidays", color: .green)
            ],
            events: [
                event("planning", "work", "Planning week", date(14), date(19), allDay: true),
                event("focus", "work", "Focus time", date(16, 9), date(16, 10)),
                event("review", "work", "Design review", date(16, 10, 30), date(16, 11, 15),
                      location: "Studio · Room 2",
                      notes: "Compare the two icon directions.\n\nAgree on the next steps and choose a date for the next review."),
                event("lunch", "personal", "Lunch with Alex", date(16, 12), date(16, 13)),
                event("check-in", "work", "Project check-in", date(16, 14), date(16, 14, 30)),
                event("walk", "personal", "Afternoon walk", date(16, 16), date(16, 16, 45)),
                event("swim", "personal", "Swimming", date(16, 18), date(16, 19)),
                event("dinner", "family", "Family dinner", date(16, 19, 30), date(16, 20, 30)),
                event("coffee", "personal", "Coffee with Sam", date(4, 11), date(4, 12)),
                event("workshop", "work", "Team workshop", date(8, 10), date(8, 12)),
                event("friends", "personal", "Dinner with friends", date(11, 19), date(11, 21)),
                event("notes", "work", "Release notes", date(22, 14), date(22, 15)),
                event("weekend", "family", "Weekend away", date(25), date(28), allDay: true)
            ]
        )
    }

    func requestAccess() async -> CalendarAccess { access }
    func load(from start: Date, to end: Date) async throws -> CalendarSnapshot { snapshot }
}

@main
private struct DocumentationScreenshots {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        app.appearance = NSAppearance(named: .aqua)
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)

        Task { @MainActor in
            do {
                for scenario in ["overview", "event-details", "calendar-filter", "expanded-agenda", "help", "calendar-access"] {
                    try await capture(scenario, output: output)
                }
                app.terminate(nil)
            } catch {
                fputs("Screenshot generation failed: \(error)\n", stderr)
                exit(1)
            }
        }
        app.run()
    }

    @MainActor
    private static func capture(_ scenario: String, output: URL) async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        let today = calendar.date(from: DateComponents(year: 2026, month: 9, day: 16, hour: 9))!
        let suite = "io.github.nimbusline.mewnu.documentation.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let service = DocumentationCalendarService(
            access: scenario == "calendar-access" ? .denied : .allowed, calendar: calendar)
        let model = CalendarViewModel(service: service, defaults: defaults, calendar: calendar, now: { today })
        await model.activate()
        let windowSize = MenuWindowSize(defaults: defaults)
        if scenario == "expanded-agenda" { windowSize.saveHeight(900, maximum: 1_000) }
        if scenario == "event-details" { model.selectedEvent = model.events.first { $0.id == "review" } }
        if scenario == "calendar-filter" {
            model.showingCalendars = true
            model.setVisible(false, calendarID: "holidays")
        }

        let root = ContentView(documentationModel: model, windowSize: windowSize, help: scenario == "help")
            .environment(\.locale, Locale(identifier: "en_GB"))
            .environment(\.calendar, calendar)
            .environment(\.timeZone, calendar.timeZone)
            .environment(\.displayScale, 2)
        let host = NSHostingView(rootView: root)
        host.wantsLayer = true
        host.layer?.contentsScale = 2
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        let maximum = min(MenuWindowSize.maximumHeight, (screen?.visibleFrame.height ?? 800) - 24)
        let frame = NSRect(x: 0, y: 0, width: MenuWindowSize.width, height: windowSize.height(maximum: maximum))
        let window = DocumentationWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        host.frame = frame
        window.display()
        // Allow SwiftUI's task and lazy containers to finish their initial layout.
        try await Task.sleep(for: .milliseconds(400))
        host.layoutSubtreeIfNeeded()

        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                                      pixelsWide: Int(frame.width * 2), pixelsHigh: Int(frame.height * 2),
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                      isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        bitmap.size = frame.size
        host.cacheDisplay(in: host.bounds, to: bitmap)
        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        let destination = output.appendingPathComponent("mewnu-\(scenario).png")
        try png.write(to: destination)
        window.close()
        print("Rendered \(destination.lastPathComponent): \(bitmap.pixelsWide) × \(bitmap.pixelsHigh)")
    }
}
