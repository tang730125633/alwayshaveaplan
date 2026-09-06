import Foundation

@main
struct EventTimeRangeTest {
    static func main() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let day = calendar.date(from: DateComponents(year: 2026, month: 9, day: 6))!

        let sameDay = EventTimeRange.make(
            on: day,
            startHour: 11,
            startMinute: 10,
            endHour: 12,
            endMinute: 0,
            calendar: calendar
        )!
        assert(calendar.component(.day, from: sameDay.end) == 6)

        let noonToMidnight = EventTimeRange.make(
            on: day,
            startHour: 11,
            startMinute: 10,
            endHour: 0,
            endMinute: 0,
            calendar: calendar
        )!
        assert(calendar.component(.day, from: noonToMidnight.end) == 7)
        assert(noonToMidnight.end.timeIntervalSince(noonToMidnight.start) == 12 * 3600 + 50 * 60)

        let lateNightToMidnight = EventTimeRange.make(
            on: day,
            startHour: 23,
            startMinute: 10,
            endHour: 0,
            endMinute: 0,
            calendar: calendar
        )!
        assert(calendar.component(.day, from: lateNightToMidnight.end) == 7)
        assert(lateNightToMidnight.end.timeIntervalSince(lateNightToMidnight.start) == 50 * 60)

        assert(EventTimeRange.make(
            on: day,
            startHour: 11,
            startMinute: 10,
            endHour: 11,
            endMinute: 10,
            calendar: calendar
        ) == nil)

        assert(EventTimeRange.make(
            on: day,
            startHour: 24,
            startMinute: 0,
            endHour: 1,
            endMinute: 0,
            calendar: calendar
        ) == nil)

        assert(EventTimeRange.make(
            on: day,
            startHour: 1,
            startMinute: 0,
            endHour: 2,
            endMinute: 60,
            calendar: calendar
        ) == nil)

        print("EventTimeRangeTest: PASS")
    }
}
