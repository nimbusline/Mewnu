import Foundation

enum EventDisplayText {
    static func rowTime(for event: EventInfo, on date: Date, calendar: Calendar, locale: Locale) -> String {
        if event.isAllDay { return String(localized: "All day", locale: locale) }
        guard let day = calendar.dateInterval(of: .day, for: date) else {
            return time(event.start, calendar: calendar, locale: locale)
        }
        if event.start >= day.start {
            return time(event.start, calendar: calendar, locale: locale)
        }
        if event.end <= day.end {
            return String(format: String(localized: "Until %@", locale: locale),
                          time(event.end, calendar: calendar, locale: locale))
        }
        return String(localized: "Continues", locale: locale)
    }

    static func detailTime(for event: EventInfo, calendar: Calendar, locale: Locale) -> String {
        let start = date(event.start, includesTime: !event.isAllDay, calendar: calendar, locale: locale)
        if !event.isAllDay && event.start == event.end { return start }
        if event.isAllDay {
            let lastDay = event.end.addingTimeInterval(-1)
            let prefix = String(localized: "All day", locale: locale)
            guard !calendar.isDate(event.start, inSameDayAs: lastDay) else { return "\(prefix) · \(start)" }
            return "\(prefix) · \(start) – \(date(lastDay, includesTime: false, calendar: calendar, locale: locale))"
        }
        return "\(start) – \(date(event.end, includesTime: true, calendar: calendar, locale: locale))"
    }

    private static func time(_ value: Date, calendar: Calendar, locale: Locale) -> String {
        var style = Date.FormatStyle.dateTime.hour().minute().locale(locale)
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        return value.formatted(style)
    }

    private static func date(_ value: Date, includesTime: Bool, calendar: Calendar, locale: Locale) -> String {
        var style = includesTime
            ? Date.FormatStyle.dateTime.day().month(.abbreviated).year().hour().minute().locale(locale)
            : Date.FormatStyle.dateTime.day().month(.abbreviated).year().locale(locale)
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        return value.formatted(style)
    }
}
