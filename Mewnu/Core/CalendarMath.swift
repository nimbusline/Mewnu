import Foundation

enum CalendarMath {
    static func monthGrid(containing date: Date, calendar: Calendar) -> [Date] {
        guard let month = calendar.dateInterval(of: .month, for: date) else { return [] }
        let weekday = calendar.component(.weekday, from: month.start)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        guard let first = calendar.date(byAdding: .day, value: -offset, to: month.start) else { return [] }
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: first) }
    }

    static func events(on date: Date, from events: [EventInfo], calendar: Calendar) -> [EventInfo] {
        guard let day = calendar.dateInterval(of: .day, for: date) else { return [] }
        return events.filter { overlaps($0, day: day) }
            .sorted(by: eventOrder)
    }

    static func dayIndex(for gridDates: [Date], events: [EventInfo], calendar: Calendar) -> [Date: [EventInfo]] {
        guard let first = gridDates.first,
              let last = gridDates.last,
              let gridEnd = calendar.dateInterval(of: .day, for: last)?.end else { return [:] }
        let gridStart = calendar.startOfDay(for: first)
        var index: [Date: [EventInfo]] = [:]

        for event in events {
            if event.start == event.end && !event.isAllDay {
                if event.start >= gridStart && event.start < gridEnd {
                    index[calendar.startOfDay(for: event.start), default: []].append(event)
                }
                continue
            }
            guard event.end > event.start, event.start < gridEnd, event.end > gridStart else { continue }
            var dayStart = calendar.startOfDay(for: max(event.start, gridStart))
            while dayStart < gridEnd && dayStart < event.end {
                guard let day = calendar.dateInterval(of: .day, for: dayStart),
                      day.end > dayStart else { break }
                if event.start < day.end && event.end > day.start {
                    index[dayStart, default: []].append(event)
                }
                dayStart = day.end
            }
        }
        for day in index.keys {
            index[day]?.sort(by: eventOrder)
        }
        return index
    }

    private static func overlaps(_ event: EventInfo, day: DateInterval) -> Bool {
        if event.start == event.end {
            return !event.isAllDay && event.start >= day.start && event.start < day.end
        }
        return event.end > event.start && event.start < day.end && event.end > day.start
    }

    private static func eventOrder(_ lhs: EventInfo, _ rhs: EventInfo) -> Bool {
        if lhs.isAllDay != rhs.isAllDay { return lhs.isAllDay }
        if lhs.start != rhs.start { return lhs.start < rhs.start }
        let titleOrder = lhs.title.localizedStandardCompare(rhs.title)
        if titleOrder != .orderedSame { return titleOrder == .orderedAscending }
        return lhs.id < rhs.id
    }

    static func sameDay(_ lhs: Date, _ rhs: Date, calendar: Calendar) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }
}
