import Foundation
import SwiftUI

struct CalendarInfo: Identifiable, Equatable {
    let id: String
    let title: String
    let color: Color

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title
    }
}

struct EventInfo: Identifiable, Equatable {
    let id: String
    let calendarID: String
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    let location: String?
    let notes: String?
}

enum CalendarAccess: Equatable {
    case undetermined
    case allowed
    case denied
}

struct CalendarSnapshot {
    let calendars: [CalendarInfo]
    let events: [EventInfo]
}
