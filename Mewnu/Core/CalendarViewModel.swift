import AppKit
import Foundation
import OSLog
import SwiftUI

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published private(set) var access: CalendarAccess
    @Published private(set) var calendars: [CalendarInfo] = []
    @Published private(set) var events: [EventInfo] = []
    @Published private var dayEvents: [Date: [EventInfo]] = [:]
    @Published private var dayCalendarMarkers: [Date: [CalendarInfo]] = [:]
    @Published private(set) var errorMessage: String?
    @Published var selectedDate: Date
    @Published var visibleMonth: Date
    @Published var selectedEvent: EventInfo?
    @Published var showingCalendars = false

    private let service: CalendarService
    private let workspace: CalendarWorkspace
    private let defaults: UserDefaults
    private let calendar: Calendar
    private let now: () -> Date
    private let logger = Logger(subsystem: "io.github.nimbusline.mewnu", category: "view-model")
    private let hiddenKey = "hiddenCalendarIDs"
    private var refreshGeneration = 0
    private var loadTask: Task<CalendarSnapshot, Error>?
    private var storeChangeTask: Task<Void, Never>?
    private var indexedMonth: Date?
    private var lastKnownToday: Date
    @Published private var hiddenCalendarIDs: Set<String>

    init(service: CalendarService, defaults: UserDefaults = .standard, calendar: Calendar = .autoupdatingCurrent,
         workspace: CalendarWorkspace? = nil, now: @escaping () -> Date = Date.init) {
        self.service = service
        self.workspace = workspace ?? SystemCalendarWorkspace()
        self.defaults = defaults
        self.calendar = calendar
        self.now = now
        let today = now()
        self.lastKnownToday = today
        self.access = service.access
        self.selectedDate = today
        self.visibleMonth = today
        self.hiddenCalendarIDs = Set(defaults.stringArray(forKey: hiddenKey) ?? [])
        service.onChange = { [weak self] in
            Task { @MainActor in self?.scheduleStoreChangeRefresh() }
        }
    }

    var selectedDayEvents: [EventInfo] {
        dayEvents[calendar.startOfDay(for: selectedDate)] ?? []
    }

    var gridDates: [Date] {
        CalendarMath.monthGrid(containing: visibleMonth, calendar: calendar)
    }

    func isVisible(_ calendarID: String) -> Bool {
        !hiddenCalendarIDs.contains(calendarID)
    }

    func hasEvents(on date: Date) -> Bool {
        !(dayEvents[calendar.startOfDay(for: date)] ?? []).isEmpty
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: now())
    }

    func calendarMarkers(on date: Date) -> [CalendarInfo] {
        dayCalendarMarkers[calendar.startOfDay(for: date)] ?? []
    }

    func setVisible(_ visible: Bool, calendarID: String) {
        if visible { hiddenCalendarIDs.remove(calendarID) }
        else { hiddenCalendarIDs.insert(calendarID) }
        defaults.set(Array(hiddenCalendarIDs).sorted(), forKey: hiddenKey)
        rebuildDayEvents()
        logger.debug("Calendar visibility changed")
    }

    func activate() async {
        updateTodaySelection()
        access = service.access
        if access == .undetermined {
            access = await service.requestAccess()
        }
        await refresh()
    }

    func refresh() async {
        refreshGeneration &+= 1
        let generation = refreshGeneration
        loadTask?.cancel()
        loadTask = nil
        access = service.access
        guard access == .allowed else {
            calendars = []
            events = []
            dayEvents = [:]
            dayCalendarMarkers = [:]
            indexedMonth = nil
            selectedEvent = nil
            errorMessage = nil
            return
        }
        guard let first = gridDates.first,
              let last = gridDates.last,
              let end = calendar.date(byAdding: .day, value: 1, to: last) else { return }
        let month = calendar.dateInterval(of: .month, for: visibleMonth)?.start
        if indexedMonth != month {
            dayEvents = [:]
            dayCalendarMarkers = [:]
            events = []
            selectedEvent = nil
            indexedMonth = month
        }
        let task = Task { try await service.load(from: first, to: end) }
        loadTask = task
        do {
            let snapshot = try await task.value
            guard generation == refreshGeneration else { return }
            loadTask = nil
            calendars = snapshot.calendars
            events = snapshot.events
            rebuildDayEvents()
            selectedEvent = selectedEvent.flatMap { old in events.first { $0.id == old.id } }
            errorMessage = nil
        } catch {
            guard generation == refreshGeneration else { return }
            loadTask = nil
            if error is CancellationError { return }
            logger.error("Could not load events: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func select(_ date: Date) async {
        selectedDate = date
        selectedEvent = nil
        if !calendar.isDate(date, equalTo: visibleMonth, toGranularity: .month) {
            visibleMonth = date
            await refresh()
        }
    }

    func moveMonth(_ offset: Int) async {
        guard let start = calendar.dateInterval(of: .month, for: visibleMonth)?.start,
              let next = calendar.date(byAdding: .month, value: offset, to: start) else { return }
        visibleMonth = next
        selectedDate = next
        selectedEvent = nil
        await refresh()
    }

    func goToToday() async {
        let today = now()
        lastKnownToday = today
        selectedDate = today
        visibleMonth = today
        selectedEvent = nil
        await refresh()
    }

    func systemDateDidChange() async {
        updateTodaySelection()
        await refresh()
    }

    func color(for event: EventInfo) -> Color {
        calendars.first { $0.id == event.calendarID }?.color ?? .accentColor
    }

    func calendarName(for event: EventInfo) -> String {
        calendars.first { $0.id == event.calendarID }?.title ?? String(localized: "Calendar")
    }

    func openCalendar() {
        guard let url = workspace.calendarApplicationURL() else {
            errorMessage = NSLocalizedString("calendar_open_error", comment: "")
            return
        }
        workspace.openApplication(at: url) { [weak self] error in
            if let error {
                Task { @MainActor in self?.errorMessage = error.localizedDescription }
            }
        }
    }

    func openPrivacySettings() {
        workspace.openPrivacySettings()
    }

    private func rebuildDayEvents() {
        let visible = events.filter { !hiddenCalendarIDs.contains($0.calendarID) }
        dayEvents = CalendarMath.dayIndex(for: gridDates, events: visible, calendar: calendar)
        let knownIDs = Set(calendars.map(\.id))
        var markers: [Date: [CalendarInfo]] = [:]
        for (date, dayEvents) in dayEvents {
            let ids = Set(dayEvents.map(\.calendarID))
            var dayMarkers = calendars.filter { ids.contains($0.id) }
            for id in ids.subtracting(knownIDs).sorted() {
                dayMarkers.append(CalendarInfo(id: id, title: id, color: .accentColor))
            }
            markers[date] = dayMarkers
        }
        dayCalendarMarkers = markers
    }

    private func scheduleStoreChangeRefresh() {
        storeChangeTask?.cancel()
        storeChangeTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            await self?.refresh()
        }
    }

    private func updateTodaySelection() {
        let today = now()
        let wasShowingToday = calendar.isDate(selectedDate, inSameDayAs: lastKnownToday)
        lastKnownToday = today
        if wasShowingToday {
            selectedDate = today
            visibleMonth = today
        }
    }
}
