import EventKit
import Foundation

final class CalendarManager {
    private let store = EKEventStore()
    private static let targetCalendarTitle = "日程安排"

    enum CalendarError: LocalizedError {
        case accessDenied
        case noWritableCalendar

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "没有日历访问权限。请在 系统设置 > 隐私与安全性 > 日历 中允许 AlwaysHaveAPlan 访问。"
            case .noWritableCalendar:
                return "没有可写入的日历。请先在系统日历中启用一个可写日历账户。"
            }
        }
    }

    private func hasReadAccess(for status: EKAuthorizationStatus) -> Bool {
        if #available(macOS 14.0, *) {
            return status == .fullAccess
        }

        return status == .authorized
    }

    private func hasWriteAccess(for status: EKAuthorizationStatus) -> Bool {
        if #available(macOS 14.0, *) {
            return status == .fullAccess || status == .writeOnly
        }

        return status == .authorized
    }

    func requestAccessIfNeeded(completion: ((Bool) -> Void)? = nil) {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(macOS 14.0, *) {
            switch status {
            case .notDetermined:
                store.requestFullAccessToEvents { granted, _ in
                    completion?(granted)
                }
            case .fullAccess:
                completion?(true)
            default:
                completion?(false)
            }
        } else {
            switch status {
            case .notDetermined:
                store.requestAccess(to: .event) { granted, _ in
                    completion?(granted)
                }
            case .authorized:
                completion?(true)
            default:
                completion?(false)
            }
        }
    }

    func fetchCurrentEvents(completion: @escaping ([EKEvent]) -> Void) {
        let status = EKEventStore.authorizationStatus(for: .event)
        let isAuthorized = hasReadAccess(for: status)

        guard isAuthorized else {
            Log.info("Calendar auth not granted. status=\(status.rawValue)")
            completion([])
            return
        }

        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now.addingTimeInterval(-86400)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86400)

        let excludedCalendars: Set<String> = ["中国大陆节假日"]
        let allCalendars = store.calendars(for: .event)
        let calendars = allCalendars.filter { !excludedCalendars.contains($0.title) }
        Log.info("Calendar fetch: using calendars count=\(calendars.count) titles=\(calendars.map { $0.title })")
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        let matched = store.events(matching: predicate)
        let events = matched.filter {
            $0.startDate <= now && $0.endDate > now
        }

        if !events.isEmpty {
            let titles = events.prefix(5).map { ($0.title ?? "(nil)") }
            Log.info("Calendar current events sample=\(titles)")
        } else {
            let formatter = ISO8601DateFormatter()
            let nearby = matched
                .sorted { $0.startDate < $1.startDate }
                .filter { abs($0.startDate.timeIntervalSince(now)) < 3 * 3600 || abs($0.endDate.timeIntervalSince(now)) < 3 * 3600 }
                .prefix(5)
                .map { "\($0.title ?? "(nil)") [\(formatter.string(from: $0.startDate)) - \(formatter.string(from: $0.endDate))]" }
            Log.info("Calendar current events none. Nearby=\(nearby)")
        }

        completion(events.sorted { $0.startDate < $1.startDate })
    }

    func createEvent(title: String, startDate: Date, endDate: Date, completion: @escaping (Bool, Error?) -> Void) {
        let status = EKEventStore.authorizationStatus(for: .event)
        let isAuthorized = hasWriteAccess(for: status)

        guard isAuthorized else {
            if status == .notDetermined {
                requestAccessIfNeeded { [weak self] granted in
                    guard let self else { return }
                    if granted {
                        self.createEvent(title: title, startDate: startDate, endDate: endDate, completion: completion)
                    } else {
                        Log.info("Calendar access request denied while creating event")
                        completion(false, CalendarError.accessDenied)
                    }
                }
                return
            }

            Log.info("Calendar auth not granted for creating event status=\(status.rawValue)")
            completion(false, CalendarError.accessDenied)
            return
        }

        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate

        if let defaultCalendar = store.defaultCalendarForNewEvents {
            event.calendar = defaultCalendar
        } else if let fallbackCalendar = store.calendars(for: .event).first(where: { $0.allowsContentModifications }) {
            event.calendar = fallbackCalendar
        } else {
            let error = CalendarError.noWritableCalendar
            Log.info("Failed to create event: \(error.localizedDescription)")
            completion(false, error)
            return
        }

        do {
            try store.save(event, span: .thisEvent)
            Log.info("Event created: \(title) [\(startDate) - \(endDate)]")
            completion(true, nil)
        } catch {
            Log.info("Failed to create event: \(error)")
            completion(false, error)
        }
    }
}
