import Foundation

enum EventTimeRange {
    static func make(
        on day: Date,
        startHour: Int,
        startMinute: Int,
        endHour: Int,
        endMinute: Int,
        calendar: Calendar = .current
    ) -> (start: Date, end: Date)? {
        guard (0..<24).contains(startHour),
              (0..<60).contains(startMinute),
              (0..<24).contains(endHour),
              (0..<60).contains(endMinute) else {
            return nil
        }

        let startOfDay = calendar.startOfDay(for: day)
        guard let start = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: startOfDay),
              var end = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: startOfDay),
              end != start else {
            return nil
        }

        if end < start {
            guard let nextDayEnd = calendar.date(byAdding: .day, value: 1, to: end) else {
                return nil
            }
            end = nextDayEnd
        }

        return (start, end)
    }
}
