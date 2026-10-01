import Foundation
import XCTest
@testable import Mewnu

final class EventDisplayTextTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return value
    }

    private let locale = Locale(identifier: "en_US")

    func testOvernightEventUsesSelectedDayContext() {
        let start = date(2026, 10, 24, 23)
        let end = date(2026, 10, 25, 2)
        let event = EventInfo(id: "overnight", calendarID: "work", title: "Trip",
                              start: start, end: end, isAllDay: false, location: nil, notes: nil)
        let firstDay = EventDisplayText.rowTime(for: event, on: start, calendar: calendar, locale: locale)
        let nextDay = EventDisplayText.rowTime(for: event, on: end, calendar: calendar, locale: locale)
        XCTAssertEqual(firstDay, start.formatted(timeStyle))
        XCTAssertEqual(nextDay, String(format: String(localized: "Until %@", locale: locale),
                                         end.formatted(timeStyle)))
        let details = EventDisplayText.detailTime(for: event, calendar: calendar, locale: locale)
        XCTAssertTrue(details.contains("24"))
        XCTAssertTrue(details.contains("25"))
    }

    func testLongEventDistinguishesMiddleAndFinalDayAcrossDaylightSaving() {
        let start = date(2026, 10, 24, 23)
        let end = date(2026, 10, 26, 1)
        let event = EventInfo(id: "long", calendarID: "work", title: "Trip",
                              start: start, end: end, isAllDay: false, location: nil, notes: nil)
        XCTAssertEqual(EventDisplayText.rowTime(for: event, on: date(2026, 10, 25),
                                                calendar: calendar, locale: locale),
                       String(localized: "Continues", locale: locale))
        XCTAssertEqual(EventDisplayText.rowTime(for: event, on: date(2026, 10, 26),
                                                calendar: calendar, locale: locale),
                       String(format: String(localized: "Until %@", locale: locale),
                              end.formatted(timeStyle)))
    }

    func testAllDayDetailUsesInclusiveLastDayWithoutTime() {
        let single = EventInfo(id: "single", calendarID: "work", title: "Holiday",
                               start: date(2026, 10, 24), end: date(2026, 10, 25),
                               isAllDay: true, location: nil, notes: nil)
        let multi = EventInfo(id: "multi", calendarID: "work", title: "Holiday",
                              start: date(2026, 10, 24), end: date(2026, 10, 27),
                              isAllDay: true, location: nil, notes: nil)
        let singleText = EventDisplayText.detailTime(for: single, calendar: calendar, locale: locale)
        let multiText = EventDisplayText.detailTime(for: multi, calendar: calendar, locale: locale)
        XCTAssertTrue(singleText.contains("24"))
        XCTAssertFalse(singleText.contains("25"))
        XCTAssertTrue(multiText.contains("24"))
        XCTAssertTrue(multiText.contains("26"))
        XCTAssertFalse(multiText.contains("27"))
        XCTAssertEqual(EventDisplayText.rowTime(for: multi, on: date(2026, 10, 25),
                                                calendar: calendar, locale: locale),
                       String(localized: "All day", locale: locale))
    }

    func testPointEventUsesOneDateAndTimeInBothLanguages() {
        let start = date(2026, 10, 25, 9)
        let event = EventInfo(id: "point", calendarID: "work", title: "Point",
                              start: start, end: start, isAllDay: false, location: nil, notes: nil)
        for identifier in ["en_US", "de_DE"] {
            let locale = Locale(identifier: identifier)
            var dateStyle = Date.FormatStyle.dateTime.day().month(.abbreviated).year().hour().minute().locale(locale)
            dateStyle.calendar = calendar
            dateStyle.timeZone = calendar.timeZone
            XCTAssertEqual(EventDisplayText.detailTime(for: event, calendar: calendar, locale: locale), start.formatted(dateStyle))
            var timeStyle = Date.FormatStyle.dateTime.hour().minute().locale(locale)
            timeStyle.calendar = calendar
            timeStyle.timeZone = calendar.timeZone
            XCTAssertEqual(EventDisplayText.rowTime(for: event, on: start, calendar: calendar, locale: locale), start.formatted(timeStyle))
        }
    }

    private var timeStyle: Date.FormatStyle {
        var style = Date.FormatStyle.dateTime.hour().minute().locale(locale)
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        return style
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
}
