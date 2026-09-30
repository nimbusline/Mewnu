import AppKit
import SwiftUI
import XCTest
@testable import Mewnu

@MainActor
final class ContentViewRenderingTests: XCTestCase {
    private final class FakeService: CalendarService {
        var onChange: (() -> Void)?
        var access: CalendarAccess = .allowed
        var includeEvent = true
        func requestAccess() async -> CalendarAccess { access }
        func load(from start: Date, to end: Date) async throws -> CalendarSnapshot {
            let event = EventInfo(id: "event", calendarID: "work", title: "Meeting", start: Date(),
                                  end: Date().addingTimeInterval(3600), isAllDay: false,
                                  location: "Office", notes: "Notes")
            return CalendarSnapshot(
                calendars: [CalendarInfo(id: "work", title: "Work", color: .blue)],
                events: includeEvent ? [event] : []
            )
        }
    }

    func testCalendarPickerAndPermissionViewsRender() async {
        let service = FakeService()
        let model = CalendarViewModel(service: service)
        await model.activate()
        XCTAssertGreaterThan(render(model).width, 0)

        service.includeEvent = false
        await model.refresh()
        XCTAssertTrue(model.selectedDayEvents.isEmpty)
        XCTAssertGreaterThan(render(model).height, 0)

        model.showingCalendars = true
        XCTAssertGreaterThan(render(model).height, 0)

        service.access = .denied
        await model.activate()
        XCTAssertGreaterThan(render(model).height, 0)

        service.access = .undetermined
        await model.activate()
        XCTAssertEqual(model.access, .undetermined)
        XCTAssertGreaterThan(render(model).height, 0)
    }

    func testEventDetailsRenderWithAndWithoutOptionalFields() {
        let now = Date()
        let timed = EventInfo(id: "timed", calendarID: "work", title: "Meeting", start: now,
                              end: now.addingTimeInterval(3600), isAllDay: false,
                              location: "Office", notes: "Notes")
        let allDay = EventInfo(id: "all-day", calendarID: "work", title: "", start: now,
                               end: now.addingTimeInterval(86400), isAllDay: true,
                               location: nil, notes: nil)
        XCTAssertGreaterThan(render(EventDetailView(event: timed, color: .blue,
                                                    calendarName: "Work", calendar: .current,
                                                    locale: .current, onClose: {})).width, 0)
        XCTAssertGreaterThan(render(EventDetailView(event: allDay, color: .red,
                                                    calendarName: "Personal", calendar: .current,
                                                    locale: .current, onClose: {})).height, 0)
    }

    func testDayIndicatorsShowFourDotsThenCompactOverflow() {
        let calendars = (0..<50).map {
            CalendarInfo(id: "\($0)", title: "Calendar \($0)", color: .red)
        }
        XCTAssertEqual(DayIndicators(calendars: []).dots.count, 0)
        XCTAssertEqual(DayIndicators(calendars: Array(calendars.prefix(4))).dots.count, 4)
        XCTAssertEqual(DayIndicators(calendars: Array(calendars.prefix(4))).overflowCount, 0)
        XCTAssertTrue(DayIndicators(calendars: Array(calendars.prefix(4))).accessibilityValue.contains("Calendar 3"))
        XCTAssertEqual(DayIndicators(calendars: Array(calendars.prefix(1))).totalCount, 1)
        XCTAssertFalse(DayIndicators(calendars: Array(calendars.prefix(1))).accessibilityValue.isEmpty)
        XCTAssertEqual(DayIndicators(calendars: Array(calendars.prefix(5))).dots.map(\.id), ["0", "1", "2"])
        XCTAssertEqual(DayIndicators(calendars: Array(calendars.prefix(5))).overflowCount, 2)
        XCTAssertEqual(DayIndicators(calendars: calendars).overflowCount, 47)
        XCTAssertTrue(DayIndicators(calendars: calendars).accessibilityValue.contains("Calendar 0"))
        XCTAssertTrue(DayIndicators(calendars: calendars).accessibilityValue.contains("47"))
    }

    private func render(_ model: CalendarViewModel) -> NSSize {
        let suite = "MewnuRenderingTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        return render(ContentView(model: model, windowSize: MenuWindowSize(defaults: defaults)))
    }

    private func render<V: View>(_ view: V) -> NSSize {
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(x: 0, y: 0, width: MenuWindowSize.width,
                            height: MenuWindowSize.defaultHeight)
        host.layoutSubtreeIfNeeded()
        return host.fittingSize
    }
}
