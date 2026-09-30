import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var model: CalendarViewModel
    @ObservedObject var windowSize: MenuWindowSize
    @Environment(\.locale) private var locale
    @Environment(\.calendar) private var calendar
    @State private var showingHelp = false
    @State private var resizeStartHeight: CGFloat?
    @State private var resizePreviewHeight: CGFloat?

    private var maximumWindowHeight: CGFloat {
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        return min(MenuWindowSize.maximumHeight, (screen?.visibleFrame.height ?? 800) - 24)
    }

    private var displayedHeight: CGFloat {
        resizePreviewHeight ?? windowSize.height(maximum: maximumWindowHeight)
    }

    private var helpButtonLabel: String {
        showingHelp ? String(localized: "Back") : String(localized: "Help")
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if showingHelp {
                helpContent
            } else if model.access == .allowed {
                if let event = model.selectedEvent {
                    EventDetailView(event: event, color: model.color(for: event),
                                    calendarName: model.calendarName(for: event),
                                    calendar: calendar, locale: locale) {
                        model.selectedEvent = nil
                    }
                } else if model.showingCalendars { calendarPicker }
                else { calendarContent }
            } else {
                permissionContent
            }
            Divider()
            footer
            resizeHandle
        }
        .frame(width: MenuWindowSize.width, height: displayedHeight)
        .background(Color(nsColor: .windowBackgroundColor))
        .task { await model.activate() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await model.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            Task { await model.systemDateDidChange() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in
            Task { await model.systemDateDidChange() }
        }
        .onExitCommand {
            if showingHelp { showingHelp = false }
            else if model.selectedEvent != nil { model.selectedEvent = nil }
            else { model.showingCalendars = false }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image("MenuIcon")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundStyle(.primary)
                .accessibilityHidden(true)
            Text("Mewnu").font(.headline)
            Spacer()
            if model.access == .allowed && model.selectedEvent == nil && !showingHelp {
                IconActionButton(
                    symbol: model.showingCalendars ? "calendar" : "line.3.horizontal.decrease",
                    label: model.showingCalendars ? String(localized: "Show calendar") : String(localized: "Choose calendars"),
                    identifier: "calendarFilterButton"
                ) {
                    model.showingCalendars.toggle()
                }
            }
        }
        .frame(minHeight: 28)
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
    }

    private var calendarContent: some View {
        VStack(spacing: 0) {
            HStack {
                Text(model.visibleMonth.formatted(.dateTime.month(.wide).year().locale(locale)))
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier("monthTitle")
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button { Task { await model.goToToday() } } label: { Text("Today") }
                    .frame(minHeight: 28)
                    .accessibilityIdentifier("todayButton")
                Button { Task { await model.moveMonth(-1) } } label: {
                    Image(systemName: "chevron.left").frame(width: 28, height: 28).contentShape(Rectangle())
                }
                    .accessibilityLabel("Previous month")
                    .accessibilityIdentifier("previousMonthButton")
                Button { Task { await model.moveMonth(1) } } label: {
                    Image(systemName: "chevron.right").frame(width: 28, height: 28).contentShape(Rectangle())
                }
                    .accessibilityLabel("Next month")
                    .accessibilityIdentifier("nextMonthButton")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)
            .padding(.top, 15)
            .padding(.bottom, 10)

            MonthGridView(model: model, calendar: calendar, locale: locale)
                .padding(.horizontal, 13)
            Divider().padding(.top, 12)
            agenda
        }
    }

    private var agenda: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(model.selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(locale)))
                    .font(.subheadline.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(model.selectedDayEvents.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            if model.selectedDayEvents.isEmpty {
                ContentUnavailableView("No events", systemImage: "calendar.badge.checkmark")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 3) {
                        ForEach(model.selectedDayEvents) { event in
                            Button {
                                model.selectedEvent = event
                            } label: {
                                EventRow(event: event, color: model.color(for: event),
                                         calendarName: model.calendarName(for: event),
                                         selectedDate: model.selectedDate, calendar: calendar, locale: locale)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(eventRowLabel(event))
                            .accessibilityHint("Show event details")
                            .accessibilityIdentifier("eventRow_\(event.id)")
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var calendarPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendars").font(.title3.weight(.semibold))
                .accessibilityIdentifier("calendarPickerTitle")
                .accessibilityAddTraits(.isHeader)
            Text("Select the calendars to show in Mewnu.")
                .font(.subheadline).foregroundStyle(.secondary)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(model.calendars) { item in
                        Toggle(isOn: Binding(
                            get: { model.isVisible(item.id) },
                            set: { model.setVisible($0, calendarID: item.id) }
                        )) {
                            HStack(spacing: 9) {
                                Circle().fill(item.color).frame(width: 9, height: 9)
                                    .accessibilityHidden(true)
                                Text(item.title).lineLimit(2)
                            }
                        }
                        .toggleStyle(.checkbox)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("calendarToggle_\(item.id)")
                        .padding(.vertical, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
        }
        .padding(18)
    }

    private var helpContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Help").font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("helpTitle")
                Label("Choose a day to see its events. Colored dots show the calendars with events.",
                      systemImage: "calendar")
                Label("Use the filter button to choose which calendars appear.",
                      systemImage: "line.3.horizontal.decrease")
                Label("Select an event for details. Press Escape to return to the calendar.",
                      systemImage: "return")
                Label("Drag the handle at the bottom to resize the event list.",
                      systemImage: "arrow.up.and.down")
                Label("Open Apple Calendar to create or edit events.",
                      systemImage: "arrow.up.forward.app")
                Text("If calendar access was denied, enable Mewnu in System Settings → Privacy & Security → Calendars.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
        }
        .frame(maxHeight: .infinity)
    }

    private func eventRowLabel(_ event: EventInfo) -> String {
        let title = event.title.isEmpty ? String(localized: "Untitled event") : event.title
        let time = EventDisplayText.rowTime(for: event, on: model.selectedDate,
                                            calendar: calendar, locale: locale)
        return "\(title), \(time), \(model.calendarName(for: event))"
    }

    private var permissionContent: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 14) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 34))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text("Calendar access needed")
                        .font(.title2.weight(.bold))
                        .accessibilityAddTraits(.isHeader)
                    if model.access == .undetermined {
                        Text("Mewnu needs permission to display your events. It does not change them.")
                    } else {
                        Text("To enable access, open System Settings → Privacy & Security → Calendars. Turn on Mewnu and choose Full Access.")
                    }
                    VStack(spacing: 8) {
                        if model.access == .undetermined {
                            Button { Task { await model.activate() } } label: {
                                Text("Allow access").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("allowCalendarAccessButton")
                        } else {
                            Button { model.openPrivacySettings() } label: {
                                Text("Open Calendar Settings").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("openCalendarSettingsButton")
                            Button { Task { await model.refresh() } } label: {
                                Text("Check access again").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("checkCalendarAccessButton")
                        }
                    }
                    .frame(maxWidth: 280)
                    .controlSize(.large)
                }
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            if let error = model.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red).lineLimit(1)
                    .help(error)
                    .layoutPriority(-1)
            }
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                IconActionButton(
                    symbol: showingHelp ? "chevron.left" : "questionmark.circle",
                    label: helpButtonLabel,
                    identifier: "helpButton"
                ) {
                    if showingHelp {
                        showingHelp = false
                    } else {
                        model.selectedEvent = nil
                        model.showingCalendars = false
                        showingHelp = true
                    }
                }
                IconActionButton(symbol: "calendar", label: String(localized: "Open Calendar"),
                                 identifier: "openCalendarButton") {
                    model.openCalendar()
                }
                IconActionButton(symbol: "power", label: String(localized: "Quit"),
                                 identifier: "quitButton") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .fixedSize()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    private var resizeHandle: some View {
        Capsule()
            .fill(.secondary.opacity(0.55))
            .frame(width: 36, height: 4)
            .frame(maxWidth: .infinity)
            .frame(height: 16)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 2)
                .onChanged { gesture in
                    if resizeStartHeight == nil { resizeStartHeight = displayedHeight }
                    resizePreviewHeight = MenuWindowSize.clamped(
                        (resizeStartHeight ?? displayedHeight) + gesture.translation.height,
                        maximum: maximumWindowHeight
                    )
                }
                .onEnded { _ in
                    if let resizePreviewHeight {
                        windowSize.saveHeight(resizePreviewHeight, maximum: maximumWindowHeight)
                    }
                    resizeStartHeight = nil
                    resizePreviewHeight = nil
                })
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(String(localized: "Resize window height")), "
                + String(format: NSLocalizedString("Window height: %d points", comment: ""),
                         Int(displayedHeight)))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: windowSize.saveHeight(displayedHeight + 40, maximum: maximumWindowHeight)
                case .decrement: windowSize.saveHeight(displayedHeight - 40, maximum: maximumWindowHeight)
                @unknown default: break
                }
            }
            .accessibilityIdentifier("resizeWindowHandle")
            .help("Drag to change the window height")
    }
}

// Native borderless buttons retain macOS hover, press, and keyboard-focus feedback.
private struct IconActionButton: View {
    let symbol: String
    let label: String
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.primary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .controlSize(.regular)
        .accessibilityLabel(label)
        .help(label)
        .accessibilityIdentifier(identifier)
    }
}

private struct EventRow: View {
    let event: EventInfo
    let color: Color
    let calendarName: String
    let selectedDate: Date
    let calendar: Calendar
    let locale: Locale

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 4)
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title.isEmpty ? String(localized: "Untitled event") : event.title)
                    .font(.subheadline.weight(.medium)).lineLimit(1)
                HStack(spacing: 4) {
                    Text(EventDisplayText.rowTime(for: event, on: selectedDate,
                                                  calendar: calendar, locale: locale))
                    Text("·")
                    Text(calendarName).lineLimit(1)
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
        }
        .frame(height: 42)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct EventDetailView: View {
    let event: EventInfo
    let color: Color
    let calendarName: String
    let calendar: Calendar
    let locale: Locale
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Circle().fill(color).frame(width: 10, height: 10)
                    .accessibilityHidden(true)
                Text(event.title.isEmpty ? String(localized: "Untitled event") : event.title)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark").frame(width: 28, height: 28).contentShape(Rectangle())
                }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction)
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("closeEventDetailsButton")
            }
            Text(calendarName).font(.subheadline).foregroundStyle(.secondary)
            Text(EventDisplayText.detailTime(for: event, calendar: calendar, locale: locale))
            if let location = event.location, !location.isEmpty {
                Label(location, systemImage: "mappin.and.ellipse")
            }
            if let notes = event.notes, !notes.isEmpty {
                ScrollView { Text(notes).frame(maxWidth: .infinity, alignment: .leading) }
                    .frame(maxHeight: 120)
            }
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
