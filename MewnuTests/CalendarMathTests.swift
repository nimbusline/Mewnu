import XCTest
@testable import Mewnu

final class CalendarMathTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Europe/Berlin")!
        value.firstWeekday = 2
        return value
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func event(_ id: String, _ start: Date, _ end: Date, allDay: Bool = false) -> EventInfo {
        EventInfo(id: id, calendarID: "one", title: id, start: start, end: end,
                  isAllDay: allDay, location: nil, notes: nil)
    }

    func testMonthGridStartsOnConfiguredWeekdayAndSpansSixWeeks() {
        let dates = CalendarMath.monthGrid(containing: date(2026, 9, 29), calendar: calendar)
        XCTAssertEqual(dates.count, 42)
        XCTAssertEqual(dates.first, date(2026, 8, 31))
        XCTAssertEqual(dates.last, date(2026, 10, 11))
    }

    func testMultiDayAndAllDayEventsOverlapCorrectDays() {
        let allDay = event("all", date(2026, 9, 29), date(2026, 9, 30), allDay: true)
        let overnight = event("overnight", date(2026, 9, 29, 23), date(2026, 9, 30, 1))
        let endingAtMidnight = event("ends", date(2026, 9, 28, 23), date(2026, 9, 29))
        let events = [overnight, endingAtMidnight, allDay]
        XCTAssertEqual(CalendarMath.events(on: date(2026, 9, 29), from: events, calendar: calendar).map(\.id), ["all", "overnight"])
        XCTAssertEqual(CalendarMath.events(on: date(2026, 9, 30), from: events, calendar: calendar).map(\.id), ["overnight"])
    }

    func testDaylightSavingChangeUsesCalendarDays() {
        let start = date(2026, 10, 25)
        let next = calendar.date(byAdding: .day, value: 1, to: start)!
        XCTAssertEqual(next.timeIntervalSince(start), 25 * 3600)
        let event = event("late", date(2026, 10, 25, 23), next)
        XCTAssertEqual(CalendarMath.events(on: start, from: [event], calendar: calendar).count, 1)
        XCTAssertTrue(CalendarMath.events(on: next, from: [event], calendar: calendar).isEmpty)
    }

    func testAllDayEventsSortBeforeTimedEvents() {
        let day = date(2026, 9, 29)
        let timed = event("timed", date(2026, 9, 29, 9), date(2026, 9, 29, 10))
        let allDay = event("all", day, date(2026, 9, 30), allDay: true)
        XCTAssertEqual(CalendarMath.events(on: day, from: [timed, allDay], calendar: calendar).map(\.id), ["all", "timed"])
    }

    func testDayIndexHonorsExclusiveEndsAndMultiDayAllDayEvents() {
        let grid = CalendarMath.monthGrid(containing: date(2026, 9, 29), calendar: calendar)
        let allDay = event("all", date(2026, 9, 29), date(2026, 10, 2), allDay: true)
        let overnight = event("night", date(2026, 9, 30, 23), date(2026, 10, 1, 1))
        let endingAtMidnight = event("ends", date(2026, 9, 28, 23), date(2026, 9, 29))
        let index = CalendarMath.dayIndex(for: grid, events: [overnight, allDay, endingAtMidnight], calendar: calendar)

        XCTAssertEqual(index[date(2026, 9, 28)]?.map(\.id), ["ends"])
        XCTAssertEqual(index[date(2026, 9, 29)]?.map(\.id), ["all"])
        XCTAssertEqual(index[date(2026, 9, 30)]?.map(\.id), ["all", "night"])
        XCTAssertEqual(index[date(2026, 10, 1)]?.map(\.id), ["all", "night"])
        XCTAssertNil(index[date(2026, 10, 2)])
    }

    func testDayIndexAcrossDaylightSavingAndGridBoundaries() {
        let grid = CalendarMath.monthGrid(containing: date(2026, 10, 15), calendar: calendar)
        let longEvent = event("long", date(2026, 1, 1), date(2027, 1, 1))
        let shortEvent = event("dst", date(2026, 10, 24, 23), date(2026, 10, 26))
        let before = event("before", date(2026, 1, 1), grid[0])
        let after = event("after", calendar.date(byAdding: .day, value: 1, to: grid[41])!, date(2027, 1, 1))
        let index = CalendarMath.dayIndex(for: grid, events: [after, shortEvent, longEvent, before], calendar: calendar)

        XCTAssertEqual(index.count, 42)
        XCTAssertEqual(index[date(2026, 10, 24)]?.map(\.id), ["long", "dst"])
        XCTAssertEqual(index[date(2026, 10, 25)]?.map(\.id), ["long", "dst"])
        XCTAssertEqual(index[date(2026, 10, 26)]?.map(\.id), ["long"])
        XCTAssertTrue(index.values.flatMap { $0 }.allSatisfy { $0.id != "before" && $0.id != "after" })
    }

    func testManyEventsRemainAvailableAndOrdered() {
        let grid = CalendarMath.monthGrid(containing: date(2026, 9, 29), calendar: calendar)
        let day = date(2026, 9, 29)
        let end = calendar.date(byAdding: .minute, value: 30, to: day)!
        let events = (0..<10_000).reversed().map { event(String(format: "%05d", $0), day, end) }
        let index = CalendarMath.dayIndex(for: grid, events: events, calendar: calendar)

        XCTAssertEqual(index[day]?.count, 10_000)
        XCTAssertEqual(index[day]?.first?.id, "00000")
        XCTAssertEqual(index[day]?.last?.id, "09999")
        XCTAssertEqual(index.count, 1)
    }

    func testRecurrenceOccurrencesAreIndexedIndividually() {
        let grid = CalendarMath.monthGrid(containing: date(2026, 10, 15), calendar: calendar)
        // EventKit supplies concrete occurrences; an edited or cancelled instance
        // is represented only by the occurrences actually returned by the store.
        let first = event("series-1", date(2026, 10, 18, 9), date(2026, 10, 18, 10))
        let edited = event("series-2", date(2026, 10, 25, 11), date(2026, 10, 25, 12))
        let third = event("series-3", date(2026, 11, 1, 9), date(2026, 11, 1, 10))
        let index = CalendarMath.dayIndex(for: grid, events: [third, first, edited], calendar: calendar)

        XCTAssertEqual(index[date(2026, 10, 18)]?.map(\.id), ["series-1"])
        XCTAssertEqual(index[date(2026, 10, 25)]?.map(\.id), ["series-2"])
        XCTAssertEqual(index[date(2026, 11, 1)]?.map(\.id), ["series-3"])
        XCTAssertNil(index[date(2026, 10, 19)])
    }

    func testSameDayUsesCalendarBoundary() {
        XCTAssertTrue(CalendarMath.sameDay(date(2026, 9, 29, 1), date(2026, 9, 29, 23), calendar: calendar))
        XCTAssertFalse(CalendarMath.sameDay(date(2026, 9, 29, 23), date(2026, 9, 30), calendar: calendar))
    }
}
