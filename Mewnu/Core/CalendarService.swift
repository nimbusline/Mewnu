import AppKit
import EventKit
import Foundation
import OSLog
import SwiftUI

@MainActor
protocol CalendarService: AnyObject {
    var onChange: (() -> Void)? { get set }
    var access: CalendarAccess { get }
    func requestAccess() async -> CalendarAccess
    func load(from start: Date, to end: Date) async throws -> CalendarSnapshot
}

@MainActor
final class EventKitCalendarService: CalendarService {
    // EventKit predates Sendable. All synchronous fetches use fetchQueue, and
    // only immutable value models cross back to the main actor.
    private struct FetchStore: @unchecked Sendable {
        let value: EKEventStore
    }

    private final class FetchCancellation: @unchecked Sendable {
        private let lock = NSLock()
        private var cancelled = false

        func cancel() {
            lock.lock()
            cancelled = true
            lock.unlock()
        }

        var isCancelled: Bool {
            lock.lock()
            defer { lock.unlock() }
            return cancelled
        }
    }

    private let store: EKEventStore
    private let authorizationStatus: () -> EKAuthorizationStatus
    private let notificationCenter: NotificationCenter
    private let fetchQueue = DispatchQueue(label: "io.github.nimbusline.mewnu.eventkit-fetch", qos: .userInitiated)
    private let logger = Logger(subsystem: "io.github.nimbusline.mewnu", category: "calendar")
    private var observer: NSObjectProtocol?
    var onChange: (() -> Void)?

    init(
        store: EKEventStore = EKEventStore(),
        authorizationStatus: @escaping () -> EKAuthorizationStatus = { EKEventStore.authorizationStatus(for: .event) },
        notificationCenter: NotificationCenter = .default
    ) {
        self.store = store
        self.authorizationStatus = authorizationStatus
        self.notificationCenter = notificationCenter
        observer = notificationCenter.addObserver(
            forName: .EKEventStoreChanged, object: store, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.logger.debug("Calendar store changed; refreshing snapshot")
                self?.onChange?()
            }
        }
    }

    deinit {
        if let observer { notificationCenter.removeObserver(observer) }
    }

    var access: CalendarAccess {
        switch authorizationStatus() {
        case .fullAccess: return .allowed
        case .notDetermined: return .undetermined
        default: return .denied
        }
    }

    func requestAccess() async -> CalendarAccess {
        do {
            let granted = try await store.requestFullAccessToEvents()
            logger.debug("Calendar permission result: \(granted)")
            return granted ? .allowed : .denied
        } catch {
            logger.error("Calendar permission request failed: \(error.localizedDescription)")
            return .denied
        }
    }

    func load(from start: Date, to end: Date) async throws -> CalendarSnapshot {
        try Task.checkCancellation()
        let store = FetchStore(value: self.store)
        let cancellation = FetchCancellation()
        let snapshot: CalendarSnapshot = try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CalendarSnapshot, Error>) in
                fetchQueue.async {
                    guard !cancellation.isCancelled else {
                        continuation.resume(throwing: CancellationError())
                        return
                    }
                    continuation.resume(returning: Self.makeSnapshot(store: store.value, from: start, to: end))
                }
            }
        }, onCancel: {
            cancellation.cancel()
        })
        try Task.checkCancellation()
        return snapshot
    }

    nonisolated private static func makeSnapshot(store: EKEventStore, from start: Date, to end: Date) -> CalendarSnapshot {
        let calendars = store.calendars(for: .event)
        guard !calendars.isEmpty else { return CalendarSnapshot(calendars: [], events: []) }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        let events = store.events(matching: predicate)
        return CalendarSnapshot(
            calendars: calendars.map {
                CalendarInfo(id: $0.calendarIdentifier, title: CalendarText.decoded($0.title),
                             color: Color(nsColor: $0.color ?? .controlAccentColor))
            }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending },
            events: events.compactMap { event in
                guard let calendar = event.calendar,
                      let startDate = event.startDate,
                      let endDate = event.endDate,
                      endDate > startDate else { return nil }
                return EventInfo(
                    id: EventIdentity.make(calendarID: calendar.calendarIdentifier,
                                           eventID: event.eventIdentifier ?? event.calendarItemIdentifier,
                                           start: startDate),
                    calendarID: calendar.calendarIdentifier,
                    title: CalendarText.decoded(event.title ?? ""),
                    start: startDate,
                    end: endDate,
                    isAllDay: event.isAllDay,
                    location: event.location,
                    notes: event.notes
                )
            }
        )
    }
}

enum EventIdentity {
    static func make(calendarID: String, eventID: String, start: Date) -> String {
        "\(calendarID.count):\(calendarID)\(eventID.count):\(eventID)\(start.timeIntervalSinceReferenceDate.bitPattern)"
    }
}
