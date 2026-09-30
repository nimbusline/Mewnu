import SwiftUI

struct MonthGridView: View {
    @ObservedObject var model: CalendarViewModel
    let calendar: Calendar
    let locale: Locale

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 2) {
                ForEach(0..<7, id: \.self) { offset in
                    Text(weekdayName(offset))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(model.gridDates, id: \.self) { date in
                    dayButton(date)
                }
            }
        }
    }

    private func weekdayName(_ offset: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        let weekday = (calendar.firstWeekday - 1 + offset) % 7
        return formatter.veryShortStandaloneWeekdaySymbols[weekday]
    }

    private func dayButton(_ date: Date) -> some View {
        let isSelected = CalendarMath.sameDay(date, model.selectedDate, calendar: calendar)
        let isToday = model.isToday(date)
        let isCurrentMonth = calendar.isDate(date, equalTo: model.visibleMonth, toGranularity: .month)
        let indicators = DayIndicators(calendars: model.calendarMarkers(on: date))
        let dateLabel = date.formatted(.dateTime.weekday(.wide).day().month(.wide).year().locale(locale))
        let dateID = String(format: "day_%04d-%02d-%02d",
                            calendar.component(.year, from: date),
                            calendar.component(.month, from: date),
                            calendar.component(.day, from: date))
        return Button { Task { await model.select(date) } } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 13, weight: isSelected ? .bold : (isToday ? .semibold : .regular)))
                    .foregroundStyle(isSelected ? .white : (isToday ? Color.accentColor : (isCurrentMonth ? .primary : .secondary)))
                HStack(spacing: 2) {
                    ForEach(indicators.dots) { item in
                        Circle()
                            .fill(item.color)
                            .frame(width: 5, height: 5)
                            .overlay {
                                if isSelected {
                                    Circle().strokeBorder(.white.opacity(0.8), lineWidth: 0.5)
                                }
                            }
                    }
                    if indicators.overflowCount > 0 {
                        Text(indicators.overflowCount > 99 ? "99+" : "+\(indicators.overflowCount)")
                            .font(.system(size: 8, weight: .semibold, design: .rounded))
                            .foregroundStyle(isSelected ? .white : .secondary)
                    }
                }
                .frame(height: 7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(isSelected ? Color.accentColor : .clear, in: RoundedRectangle(cornerRadius: 9))
            .overlay {
                if isToday && !isSelected {
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(Color.accentColor, lineWidth: 1.25)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isToday ? "\(String(localized: "Today")), \(dateLabel)" : dateLabel)
        .accessibilityValue(indicators.accessibilityValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(dateID)
    }
}

struct DayIndicators {
    let dots: [CalendarInfo]
    let overflowCount: Int
    let totalCount: Int

    init(calendars: [CalendarInfo]) {
        totalCount = calendars.count
        let dotCount = calendars.count > 4 ? 3 : calendars.count
        dots = Array(calendars.prefix(dotCount))
        overflowCount = calendars.count - dotCount
    }

    var accessibilityValue: String {
        guard totalCount > 0 else { return "" }
        let names = dots.map(\.title).joined(separator: ", ")
        if totalCount == 1 {
            return String(format: NSLocalizedString("Events in %@", comment: ""), names)
        }
        if overflowCount == 0 {
            return String(format: NSLocalizedString("Events in %d calendars: %@", comment: ""), totalCount, names)
        }
        return String(format: NSLocalizedString("Events in %d calendars: %@, and %d more", comment: ""),
                      totalCount, names, overflowCount)
    }
}
