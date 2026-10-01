import AppKit
import EventKit
import XCTest
@testable import Mewnu

@MainActor
final class EventKitCalendarServiceTests: XCTestCase {
    private final class FakeEventStore: EKEventStore {
        var fakeCalendars: [EKCalendar] = []
        var fakeEvents: [EKEvent] = []
        var requestedRange: (Date, Date)?
        var fetchWasOnMainThread: Bool?
        var requestResult = true
        var requestError: Error?
        var shouldBlockFetch = false
        let fetchStarted = DispatchSemaphore(value: 0)
        let allowFetch = DispatchSemaphore(value: 0)

        override func calendars(for entityType: EKEntityType) -> [EKCalendar] {
            if shouldBlockFetch {
                fetchStarted.signal()
                allowFetch.wait()
            }
            return fakeCalendars
        }
        override func predicateForEvents(withStart startDate: Date, end endDate: Date,
                                         calendars: [EKCalendar]?) -> NSPredicate {
            requestedRange = (startDate, endDate)
            return NSPredicate(value: true)
        }
        override func events(matching predicate: NSPredicate) -> [EKEvent] {
            fetchWasOnMainThread = Thread.isMainThread
            return fakeEvents
        }
        override func requestFullAccessToEvents() async throws -> Bool {
            if let requestError { throw requestError }
            return requestResult
        }
    }

    func testAuthorizationStatesAndPermissionOutcomes() async {
        let store = FakeEventStore()
        var status: EKAuthorizationStatus = .notDetermined
        let service = EventKitCalendarService(store: store, authorizationStatus: { status })
        XCTAssertEqual(service.access, .undetermined)
        status = .fullAccess
        XCTAssertEqual(service.access, .allowed)
        status = .denied
        XCTAssertEqual(service.access, .denied)
        status = .restricted
        XCTAssertEqual(service.access, .denied)

        let granted = await service.requestAccess()
        XCTAssertEqual(granted, .allowed)
        store.requestResult = false
        let declined = await service.requestAccess()
        XCTAssertEqual(declined, .denied)
        store.requestError = NSError(domain: "test", code: 1)
        let failed = await service.requestAccess()
        XCTAssertEqual(failed, .denied)
    }

    func testLoadMapsAndSortsCalendarsAndEvents() async throws {
        let store = FakeEventStore()
        let calendarB = EKCalendar(for: .event, eventStore: store)
        calendarB.title = "Zulu &amp; Co"
        calendarB.cgColor = NSColor.red.cgColor
        let calendarA = EKCalendar(for: .event, eventStore: store)
        calendarA.title = "Alpha"
        calendarA.cgColor = NSColor.blue.cgColor
        store.fakeCalendars = [calendarB, calendarA]

        let event = EKEvent(eventStore: store)
        event.calendar = calendarB
        event.title = "Michi &amp; Michi"
        event.location = "Office"
        event.notes = "Notes"
        event.isAllDay = false
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let end = start.addingTimeInterval(3600)
        event.startDate = start
        event.endDate = end
        store.fakeEvents = [event]

        let service = EventKitCalendarService(store: store, authorizationStatus: { .fullAccess })
        let snapshot = try await service.load(from: start, to: end)
        XCTAssertEqual(snapshot.calendars.map(\.title), ["Alpha", "Zulu & Co"])
        XCTAssertEqual(snapshot.events.count, 1)
        XCTAssertEqual(snapshot.events[0].calendarID, calendarB.calendarIdentifier)
        XCTAssertEqual(snapshot.events[0].title, "Michi & Michi")
        XCTAssertEqual(snapshot.events[0].location, "Office")
        XCTAssertEqual(snapshot.events[0].notes, "Notes")
        XCTAssertEqual(snapshot.events[0].start, start)
        XCTAssertEqual(snapshot.events[0].end, end)
        XCTAssertEqual(store.requestedRange?.0, start)
        XCTAssertEqual(store.requestedRange?.1, end)
        XCTAssertEqual(store.fetchWasOnMainThread, false)
    }

    func testStoreNotificationCallsOnChange() async {
        let center = NotificationCenter()
        let store = FakeEventStore()
        let service = EventKitCalendarService(store: store, authorizationStatus: { .fullAccess },
                                              notificationCenter: center)
        let changed = expectation(description: "calendar change")
        service.onChange = { changed.fulfill() }
        center.post(name: .EKEventStoreChanged, object: store)
        await fulfillment(of: [changed], timeout: 2)
    }

    func testCancelledFetchDoesNotReturnItsSnapshot() async {
        let store = FakeEventStore()
        store.shouldBlockFetch = true
        let service = EventKitCalendarService(store: store, authorizationStatus: { .fullAccess })
        let start = Date()
        let request = Task { try await service.load(from: start, to: start.addingTimeInterval(3600)) }
        await Task.detached { store.fetchStarted.wait() }.value
        request.cancel()
        store.allowFetch.signal()
        do {
            _ = try await request.value
            XCTFail("Cancelled fetch returned a snapshot")
        } catch is CancellationError {
            // Expected: a stale fetch must not update the view model.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDistinctFetchedOccurrencesKeepDistinctIDs() async throws {
        let store = FakeEventStore()
        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = "Recurring"
        store.fakeCalendars = [calendar]
        let first = EKEvent(eventStore: store)
        first.calendar = calendar
        first.title = "Weekly"
        first.startDate = Date(timeIntervalSince1970: 1_800_000_000)
        first.endDate = first.startDate.addingTimeInterval(3600)
        let next = EKEvent(eventStore: store)
        next.calendar = calendar
        next.title = "Weekly — changed time"
        next.startDate = first.startDate.addingTimeInterval(7 * 24 * 3600 + 7200)
        next.endDate = next.startDate.addingTimeInterval(3600)
        store.fakeEvents = [first, next]

        let snapshot = try await EventKitCalendarService(store: store, authorizationStatus: { .fullAccess })
            .load(from: first.startDate, to: next.endDate)
        XCTAssertEqual(snapshot.events.count, 2)
        XCTAssertEqual(Set(snapshot.events.map(\.id)).count, 2)
        XCTAssertEqual(snapshot.events.map(\.title), ["Weekly", "Weekly — changed time"])
    }

    func testSharedSeriesIdentifierAndEditedOccurrenceHaveDistinctIDs() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let first = EventIdentity.make(calendarID: "work", eventID: "series", start: start)
        let edited = EventIdentity.make(calendarID: "work", eventID: "series",
                                        start: start.addingTimeInterval(7 * 24 * 3600 + 7200))
        let otherCalendar = EventIdentity.make(calendarID: "personal", eventID: "series", start: start)
        XCTAssertNotEqual(first, edited)
        XCTAssertNotEqual(first, otherCalendar)
        XCTAssertEqual(first, EventIdentity.make(calendarID: "work", eventID: "series", start: start))
    }

    func testZeroDurationTimedEventIsRetained() async throws {
        let store = FakeEventStore()
        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = "Synthetic"
        store.fakeCalendars = [calendar]
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let event = EKEvent(eventStore: store)
        event.calendar = calendar
        event.title = "Point event"
        event.startDate = start
        event.endDate = start
        store.fakeEvents = [event]
        let snapshot = try await EventKitCalendarService(store: store, authorizationStatus: { .fullAccess })
            .load(from: start, to: start.addingTimeInterval(3600))
        XCTAssertEqual(snapshot.events.count, 1)
        XCTAssertEqual(snapshot.events.first?.start, start)
        XCTAssertEqual(snapshot.events.first?.end, start)
    }

    func testZeroDurationAllDayIsRejectedSeparatelyFromNegativeDuration() {
        let day = Date(timeIntervalSince1970: 1_800_000_000)
        // EKEvent setters normalize all-day end dates; test the raw import rule directly.
        XCTAssertFalse(EventKitCalendarService.isValidInterval(start: day, end: day, isAllDay: true))
        XCTAssertTrue(EventKitCalendarService.isValidInterval(start: day, end: day, isAllDay: false))
        for allDay in [true, false] {
            XCTAssertFalse(EventKitCalendarService.isValidInterval(start: day, end: day.addingTimeInterval(-1), isAllDay: allDay))
        }
    }

    func testMissingDatesAreRejected() async throws {
        let store = FakeEventStore()
        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = "Synthetic"
        store.fakeCalendars = [calendar]
        let missing = EKEvent(eventStore: store)
        missing.calendar = calendar
        store.fakeEvents = [missing]
        let day = Date(timeIntervalSince1970: 1_800_000_000)
        let snapshot = try await EventKitCalendarService(store: store, authorizationStatus: { .fullAccess })
            .load(from: day, to: day.addingTimeInterval(86400))
        XCTAssertTrue(snapshot.events.isEmpty)
    }

    func testEmptyStoreSkipsQueryAndMalformedEventsAreIgnored() async throws {
        let store = FakeEventStore()
        let service = EventKitCalendarService(store: store, authorizationStatus: { .fullAccess })
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let end = start.addingTimeInterval(3600)
        let empty = try await service.load(from: start, to: end)
        XCTAssertTrue(empty.calendars.isEmpty)
        XCTAssertNil(store.requestedRange)

        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = "Work"
        store.fakeCalendars = [calendar]
        let invalid = EKEvent(eventStore: store)
        invalid.calendar = calendar
        invalid.startDate = start
        invalid.endDate = start.addingTimeInterval(-1)
        store.fakeEvents = [invalid]
        let loaded = try await service.load(from: start, to: end)
        XCTAssertTrue(loaded.events.isEmpty)
    }
}
