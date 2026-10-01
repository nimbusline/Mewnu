import SwiftUI
import XCTest
@testable import Mewnu

@MainActor
final class CalendarViewModelTests: XCTestCase {
    private final class FakeWorkspace: CalendarWorkspace {
        var url: URL? = URL(fileURLWithPath: "/Applications/Calendar.app")
        var openedURL: URL?
        var completion: ((Error?) -> Void)?
        var privacyOpenCount = 0
        func calendarApplicationURL() -> URL? { url }
        func openApplication(at url: URL, completion: @escaping (Error?) -> Void) {
            openedURL = url
            self.completion = completion
        }
        func openPrivacySettings() { privacyOpenCount += 1 }
    }

    private final class FakeService: CalendarService {
        enum LoadError: Error { case unavailable }
        var onChange: (() -> Void)?
        var access: CalendarAccess = .allowed
        var requestedAccess: CalendarAccess = .allowed
        var snapshot = CalendarSnapshot(calendars: [], events: [])
        var loadCount = 0
        var requestCount = 0
        var shouldFailLoad = false
        var pauseNextLoad = false
        var pendingLoad: CheckedContinuation<CalendarSnapshot, Error>?
        func requestAccess() async -> CalendarAccess {
            requestCount += 1
            access = requestedAccess
            return access
        }
        func load(from start: Date, to end: Date) async throws -> CalendarSnapshot {
            loadCount += 1
            if shouldFailLoad { throw LoadError.unavailable }
            let result = snapshot
            if pauseNextLoad {
                pauseNextLoad = false
                return try await withCheckedThrowingContinuation { pendingLoad = $0 }
            }
            return result
        }
    }

    func testCalendarSelectionPersistsAndFiltersEvents() async {
        let suite = "MewnuTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let service = FakeService()
        let now = Date()
        service.snapshot = CalendarSnapshot(
            calendars: [CalendarInfo(id: "one", title: "One", color: .red), CalendarInfo(id: "two", title: "Two", color: .blue)],
            events: [EventInfo(id: "one", calendarID: "one", title: "One", start: now,
                               end: now.addingTimeInterval(3600), isAllDay: false, location: nil, notes: nil),
                     EventInfo(id: "two", calendarID: "two", title: "Two", start: now,
                               end: now.addingTimeInterval(3600), isAllDay: false, location: nil, notes: nil)]
        )
        let model = CalendarViewModel(service: service, defaults: defaults)
        await model.activate()
        XCTAssertEqual(model.selectedDayEvents.count, 2)
        XCTAssertTrue(model.hasEvents(on: now))
        model.setVisible(false, calendarID: "two")
        XCTAssertEqual(model.selectedDayEvents.map(\.id), ["one"])
        model.setVisible(false, calendarID: "one")
        XCTAssertFalse(model.hasEvents(on: now))
        model.setVisible(true, calendarID: "one")
        XCTAssertTrue(model.hasEvents(on: now))
        let restored = CalendarViewModel(service: service, defaults: defaults)
        await restored.activate()
        XCTAssertFalse(restored.isVisible("two"))
    }

    func testPointEventFilteringAlsoUpdatesDayMarkers() async {
        let service = FakeService()
        let now = Date()
        service.snapshot = CalendarSnapshot(
            calendars: [CalendarInfo(id: "point", title: "Point", color: .blue)],
            events: [EventInfo(id: "point", calendarID: "point", title: "Point", start: now,
                               end: now, isAllDay: false, location: nil, notes: nil)]
        )
        let suite = "PointEvents.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = CalendarViewModel(service: service, defaults: defaults, now: { now })
        await model.activate()
        XCTAssertEqual(model.selectedDayEvents.map(\.id), ["point"])
        XCTAssertEqual(model.calendarMarkers(on: now).map(\.id), ["point"])
        model.setVisible(false, calendarID: "point")
        XCTAssertTrue(model.selectedDayEvents.isEmpty)
        XCTAssertTrue(model.calendarMarkers(on: now).isEmpty)
        model.setVisible(true, calendarID: "point")
        XCTAssertTrue(model.hasEvents(on: now))
    }

    func testStoreChangeReloadsAndDeniedAccessClearsEvents() async {
        let service = FakeService()
        let now = Date()
        service.snapshot = CalendarSnapshot(calendars: [CalendarInfo(id: "one", title: "One", color: .red)],
                                            events: [EventInfo(id: "one", calendarID: "one", title: "One", start: now,
                                                               end: now.addingTimeInterval(3600), isAllDay: false,
                                                               location: nil, notes: nil)])
        let model = CalendarViewModel(service: service)
        await model.activate()
        XCTAssertEqual(model.events.count, 1)
        let firstCount = service.loadCount
        service.onChange?()
        await waitUntil { service.loadCount == firstCount + 1 }
        XCTAssertEqual(service.loadCount, firstCount + 1)
        service.access = .denied
        await model.activate()
        XCTAssertEqual(model.access, .denied)
        XCTAssertTrue(model.events.isEmpty)
    }

    func testBurstOfStoreChangesCausesOneReload() async throws {
        let service = FakeService()
        let model = CalendarViewModel(service: service)
        await model.activate()
        for _ in 0..<8 { service.onChange?() }
        await waitUntil { service.loadCount == 2 }
        try await Task.sleep(for: .milliseconds(250))
        XCTAssertEqual(service.loadCount, 2)
    }

    func testMonthNavigationFromThirtyFirstLandsInNextMonth() async {
        let service = FakeService()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let model = CalendarViewModel(service: service, calendar: calendar)
        await model.activate()
        let january31 = calendar.date(from: DateComponents(year: 2027, month: 1, day: 31))!
        await model.select(january31)
        await model.moveMonth(1)
        XCTAssertEqual(calendar.component(.month, from: model.visibleMonth), 2)
        XCTAssertEqual(calendar.component(.day, from: model.selectedDate), 1)
    }

    func testNewCalendarIsVisibleByDefault() async {
        let suite = "MewnuTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let service = FakeService()
        let model = CalendarViewModel(service: service, defaults: defaults)
        model.setVisible(false, calendarID: "hidden")
        XCTAssertFalse(model.isVisible("hidden"))
        XCTAssertTrue(model.isVisible("newly-added"))
    }

    func testPermissionRequestedOnceAndDeniedAccessDoesNotLoad() async {
        let service = FakeService()
        service.access = .undetermined
        service.requestedAccess = .denied
        let model = CalendarViewModel(service: service)
        await model.activate()
        XCTAssertEqual(service.requestCount, 1)
        XCTAssertEqual(service.loadCount, 0)
        XCTAssertEqual(model.access, .denied)

        service.requestedAccess = .allowed
        await model.activate()
        XCTAssertEqual(service.requestCount, 1)
        XCTAssertEqual(service.loadCount, 0)

        service.access = .allowed
        await model.refresh()
        XCTAssertEqual(service.loadCount, 1)
        XCTAssertEqual(model.access, .allowed)
        XCTAssertEqual(service.requestCount, 1)
    }

    func testLoadFailureKeepsCurrentMonthDataThenRecovers() async {
        let service = FakeService()
        let now = Date()
        service.snapshot = CalendarSnapshot(
            calendars: [CalendarInfo(id: "work", title: "Work", color: .blue)],
            events: [EventInfo(id: "meeting", calendarID: "work", title: "Meeting", start: now,
                               end: now.addingTimeInterval(3600), isAllDay: false, location: nil, notes: nil)]
        )
        let model = CalendarViewModel(service: service)
        await model.activate()
        model.selectedEvent = service.snapshot.events[0]

        service.shouldFailLoad = true
        await model.refresh()
        XCTAssertEqual(model.calendars.map(\.id), ["work"])
        XCTAssertEqual(model.events.map(\.id), ["meeting"])
        XCTAssertEqual(model.selectedEvent?.id, "meeting")
        XCTAssertEqual(model.selectedDayEvents.map(\.id), ["meeting"])
        XCTAssertNotNil(model.errorMessage)

        service.shouldFailLoad = false
        await model.refresh()
        XCTAssertEqual(model.events.map(\.id), ["meeting"])
        XCTAssertNil(model.errorMessage)

        service.access = .denied
        await model.refresh()
        XCTAssertTrue(model.events.isEmpty)
        XCTAssertNil(model.errorMessage)
    }

    func testLoadFailureInAnotherMonthDoesNotShowPreviousMonthEvents() async {
        let service = FakeService()
        let now = Date()
        service.snapshot = CalendarSnapshot(
            calendars: [CalendarInfo(id: "work", title: "Work", color: .blue)],
            events: [EventInfo(id: "meeting", calendarID: "work", title: "Meeting", start: now,
                               end: now.addingTimeInterval(3600), isAllDay: false, location: nil, notes: nil)]
        )
        let model = CalendarViewModel(service: service)
        await model.activate()
        service.shouldFailLoad = true
        await model.moveMonth(1)
        XCTAssertTrue(model.events.isEmpty)
        XCTAssertTrue(model.selectedDayEvents.isEmpty)
        XCTAssertNotNil(model.errorMessage)
    }

    func testSelectingAdjacentMonthLoadsNewGridAndClearsSelectedEvent() async {
        let service = FakeService()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let model = CalendarViewModel(service: service, calendar: calendar)
        await model.activate()
        let december = calendar.date(from: DateComponents(year: 2026, month: 12, day: 15))!
        await model.select(december)
        let before = service.loadCount
        let january = calendar.date(from: DateComponents(year: 2027, month: 1, day: 2))!
        model.selectedEvent = EventInfo(id: "old", calendarID: "work", title: "Old", start: december,
                                        end: december.addingTimeInterval(3600), isAllDay: false,
                                        location: nil, notes: nil)
        await model.select(january)
        XCTAssertEqual(service.loadCount, before + 1)
        XCTAssertEqual(calendar.component(.year, from: model.visibleMonth), 2027)
        XCTAssertEqual(calendar.component(.month, from: model.visibleMonth), 1)
        XCTAssertNil(model.selectedEvent)
    }

    func testRefreshKeepsSelectedEventWhenStillPresentAndClearsItWhenRemoved() async {
        let service = FakeService()
        let now = Date()
        let old = EventInfo(id: "same", calendarID: "one", title: "Old", start: now,
                            end: now.addingTimeInterval(3600), isAllDay: false,
                            location: nil, notes: nil)
        let updated = EventInfo(id: "same", calendarID: "one", title: "Updated", start: now,
                                end: now.addingTimeInterval(3600), isAllDay: false,
                                location: nil, notes: nil)
        service.snapshot = CalendarSnapshot(calendars: [], events: [old])
        let model = CalendarViewModel(service: service)
        await model.activate()
        model.selectedEvent = old
        service.snapshot = CalendarSnapshot(calendars: [], events: [updated])
        await model.refresh()
        XCTAssertEqual(model.selectedEvent?.title, "Updated")
        service.snapshot = CalendarSnapshot(calendars: [], events: [])
        await model.refresh()
        XCTAssertNil(model.selectedEvent)
    }

    func testTodayAndEventColor() async {
        let service = FakeService()
        service.snapshot = CalendarSnapshot(calendars: [CalendarInfo(id: "work", title: "Work", color: .red)], events: [])
        let model = CalendarViewModel(service: service)
        await model.activate()
        let oldDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        await model.select(oldDate)
        let before = service.loadCount
        await model.goToToday()
        XCTAssertTrue(Calendar.current.isDateInToday(model.selectedDate))
        XCTAssertTrue(Calendar.current.isDateInToday(model.visibleMonth))
        XCTAssertEqual(service.loadCount, before + 1)
        let event = EventInfo(id: "meeting", calendarID: "work", title: "Meeting", start: Date(),
                              end: Date().addingTimeInterval(3600), isAllDay: false,
                              location: nil, notes: nil)
        XCTAssertEqual(model.color(for: event), .red)
        XCTAssertEqual(model.calendarName(for: event), "Work")
        let unknown = EventInfo(id: "other", calendarID: "missing", title: "Other", start: Date(),
                                end: Date().addingTimeInterval(3600), isAllDay: false,
                                location: nil, notes: nil)
        XCTAssertEqual(model.color(for: unknown), .accentColor)
        XCTAssertFalse(model.calendarName(for: unknown).isEmpty)
    }

    func testCalendarAndPrivacyActionsUseWorkspaceAndReportFailure() async {
        let workspace = FakeWorkspace()
        let model = CalendarViewModel(service: FakeService(), workspace: workspace)
        workspace.url = nil
        model.openCalendar()
        XCTAssertNotNil(model.errorMessage)
        XCTAssertNil(workspace.openedURL)

        workspace.url = URL(fileURLWithPath: "/Applications/Calendar.app")
        model.openCalendar()
        XCTAssertEqual(workspace.openedURL, workspace.url)
        let failure = NSError(domain: "Calendar launch", code: 9)
        workspace.completion?(failure)
        for _ in 0..<20 where model.errorMessage != failure.localizedDescription {
            await Task.yield()
        }
        XCTAssertEqual(model.errorMessage, failure.localizedDescription)

        model.openPrivacySettings()
        XCTAssertEqual(workspace.privacyOpenCount, 1)
    }

    func testLateMonthResultCannotOverwriteNewerMonth() async {
        let service = FakeService()
        let model = CalendarViewModel(service: service)
        await model.activate()
        service.snapshot = CalendarSnapshot(calendars: [CalendarInfo(id: "old", title: "Old", color: .red)], events: [])
        service.pauseNextLoad = true
        let first = Task { await model.moveMonth(1) }
        await waitUntil { service.pendingLoad != nil }

        service.snapshot = CalendarSnapshot(calendars: [CalendarInfo(id: "new", title: "New", color: .blue)], events: [])
        await model.moveMonth(1)
        XCTAssertEqual(model.calendars.map(\.id), ["new"])

        service.pendingLoad?.resume(returning: CalendarSnapshot(
            calendars: [CalendarInfo(id: "old", title: "Old", color: .red)], events: []
        ))
        await first.value
        XCTAssertEqual(model.calendars.map(\.id), ["new"])
    }

    func testDayIndexIncludesOvernightAndMultiDayEvents() async {
        let service = FakeService()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        let start = calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 23))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 10, day: 26, hour: 1))!
        service.snapshot = CalendarSnapshot(
            calendars: [CalendarInfo(id: "work", title: "Work", color: .blue)],
            events: [EventInfo(id: "trip", calendarID: "work", title: "Trip", start: start,
                               end: end, isAllDay: false, location: nil, notes: nil)]
        )
        let model = CalendarViewModel(service: service, calendar: calendar)
        await model.select(start)
        await model.activate()
        for day in 24...26 {
            let date = calendar.date(from: DateComponents(year: 2026, month: 10, day: day))!
            XCTAssertTrue(model.hasEvents(on: date))
        }
        let next = calendar.date(from: DateComponents(year: 2026, month: 10, day: 27))!
        XCTAssertFalse(model.hasEvents(on: next))
    }

    func testCalendarMarkersDeduplicateSortFilterAndRefreshAcrossFiftyCalendars() async {
        let suite = "MewnuTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let service = FakeService()
        let now = Date()
        let calendars = (0..<50).map { index in
            CalendarInfo(id: "calendar-\(index)", title: String(format: "%02d", index),
                         color: index == 0 ? .red : .green)
        }
        let events = (0..<50).reversed().flatMap { index in
            (0..<3).map { occurrence in
                EventInfo(id: "\(index)-\(occurrence)", calendarID: "calendar-\(index)",
                          title: "Event", start: now, end: now.addingTimeInterval(3600),
                          isAllDay: false, location: nil, notes: nil)
            }
        }
        service.snapshot = CalendarSnapshot(calendars: calendars, events: events)
        let model = CalendarViewModel(service: service, defaults: defaults)
        await model.activate()

        XCTAssertEqual(model.selectedDayEvents.count, 150)
        XCTAssertEqual(model.calendarMarkers(on: now).map(\.id), calendars.map(\.id))
        XCTAssertEqual(model.calendarMarkers(on: now).first?.color, .red)

        model.setVisible(false, calendarID: "calendar-0")
        XCTAssertEqual(model.selectedDayEvents.count, 147)
        XCTAssertEqual(model.calendarMarkers(on: now).count, 49)
        XCTAssertEqual(model.calendarMarkers(on: now).first?.id, "calendar-1")

        service.snapshot = CalendarSnapshot(
            calendars: calendars.map { $0.id == "calendar-1" ? CalendarInfo(id: $0.id, title: $0.title, color: .blue) : $0 },
            events: events
        )
        await model.refresh()
        XCTAssertEqual(model.calendarMarkers(on: now).first?.color, .blue)

        service.access = .denied
        await model.refresh()
        XCTAssertTrue(model.calendarMarkers(on: now).isEmpty)
    }

    func testEventFromCalendarMissingInSnapshotStillGetsMarker() async {
        let service = FakeService()
        let now = Date()
        service.snapshot = CalendarSnapshot(
            calendars: [],
            events: [EventInfo(id: "orphan", calendarID: "missing", title: "Meeting", start: now,
                               end: now.addingTimeInterval(3600), isAllDay: false, location: nil, notes: nil)]
        )
        let model = CalendarViewModel(service: service)
        await model.activate()
        XCTAssertEqual(model.calendarMarkers(on: now).map(\.id), ["missing"])
        XCTAssertEqual(model.calendarMarkers(on: now).first?.color, .accentColor)
    }

    func testDayRolloverFollowsTodayButPreservesDeliberateDateSelection() async {
        let service = FakeService()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var clock = calendar.date(from: DateComponents(year: 2026, month: 9, day: 30, hour: 23))!
        let model = CalendarViewModel(service: service, calendar: calendar, now: { clock })
        await model.activate()
        XCTAssertTrue(model.isToday(clock))
        XCTAssertFalse(model.isToday(clock.addingTimeInterval(-24 * 3600)))

        clock = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 1))!
        await model.systemDateDidChange()
        XCTAssertTrue(model.isToday(clock))
        XCTAssertFalse(model.isToday(calendar.date(from: DateComponents(year: 2026, month: 9, day: 30))!))
        XCTAssertEqual(calendar.component(.day, from: model.selectedDate), 1)
        XCTAssertEqual(calendar.component(.month, from: model.visibleMonth), 10)

        let chosen = calendar.date(from: DateComponents(year: 2026, month: 12, day: 15))!
        await model.select(chosen)
        XCTAssertTrue(model.isToday(clock))
        clock = calendar.date(from: DateComponents(year: 2026, month: 10, day: 2, hour: 1))!
        await model.activate()
        XCTAssertEqual(model.selectedDate, chosen)
        XCTAssertEqual(calendar.component(.month, from: model.visibleMonth), 12)
    }

    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0..<100 {
            if condition() { return }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Timed out waiting for calendar refresh")
    }
}
