import Foundation

/// Egyptian Exchange trading calendar.
///
/// EGX trades Sunday to Thursday, Cairo time. Continuous trading runs from
/// 10:00 to 14:30, preceded by a pre-open session and followed by a short
/// closing auction. Public holidays are not modelled.
enum MarketClock {
    static let cairo = TimeZone(identifier: "Africa/Cairo") ?? TimeZone(secondsFromGMT: 3 * 3600)!

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = cairo
        return calendar
    }()

    static let preOpenMinute = 9 * 60 + 30
    static let openMinute = 10 * 60
    static let closeMinute = 14 * 60 + 30
    static let auctionEndMinute = 14 * 60 + 45
    /// Length of the continuous session in minutes.
    static let sessionLength = closeMinute - openMinute

    static func isTradingDay(_ date: Date) -> Bool {
        // Gregorian weekday: 1 = Sunday ... 7 = Saturday. Friday and Saturday are closed.
        let weekday = calendar.component(.weekday, from: date)
        return weekday >= 1 && weekday <= 5
    }

    static func minuteOfDay(_ date: Date) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    static func session(at date: Date = Date()) -> MarketSession {
        guard isTradingDay(date) else { return .closed }
        let minute = minuteOfDay(date)
        switch minute {
        case preOpenMinute..<openMinute: return .preOpen
        case openMinute..<closeMinute: return .open
        case closeMinute..<auctionEndMinute: return .closingAuction
        default: return .closed
        }
    }

    /// Minutes elapsed in the continuous session, clamped to the session length.
    static func sessionMinute(at date: Date = Date()) -> Int {
        min(max(minuteOfDay(date) - openMinute, 0), sessionLength)
    }

    /// Date of the most recent session that has started (today if it opened already).
    static func latestSessionDate(from date: Date = Date()) -> Date {
        var day = calendar.startOfDay(for: date)
        if isTradingDay(day) && minuteOfDay(date) >= openMinute { return day }
        repeat {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        } while !isTradingDay(day)
        return day
    }

    /// `count` trading days strictly before `date`, in ascending order.
    static func tradingDays(before date: Date, count: Int) -> [Date] {
        var result: [Date] = []
        result.reserveCapacity(count)
        var day = calendar.startOfDay(for: date)
        while result.count < count {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
            if isTradingDay(day) { result.append(day) }
        }
        return result.reversed()
    }

    static func nextOpen(after date: Date = Date()) -> Date {
        var day = calendar.startOfDay(for: date)
        if isTradingDay(day) && minuteOfDay(date) < openMinute {
            return day.addingTimeInterval(TimeInterval(openMinute * 60))
        }
        repeat {
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? day
        } while !isTradingDay(day)
        return day.addingTimeInterval(TimeInterval(openMinute * 60))
    }

    /// Timestamp for a minute offset inside the session of `day`.
    static func timestamp(day: Date, sessionMinute: Int) -> Date {
        calendar.startOfDay(for: day).addingTimeInterval(TimeInterval((openMinute + sessionMinute) * 60))
    }

    /// Human readable countdown, e.g. "Closes in 1h 12m" or "Opens Sun 10:00".
    static func statusDetail(at date: Date = Date()) -> String {
        let minute = minuteOfDay(date)
        switch session(at: date) {
        case .open:
            return "Closes in " + duration(minutes: closeMinute - minute)
        case .preOpen:
            return "Opens in " + duration(minutes: openMinute - minute)
        case .closingAuction:
            return "Auction ends in " + duration(minutes: auctionEndMinute - minute)
        case .closed:
            let next = nextOpen(after: date)
            let formatter = DateFormatter()
            formatter.timeZone = cairo
            formatter.dateFormat = calendar.isDateInTomorrow(next) ? "'Opens tomorrow' HH:mm" : "'Opens' EEE HH:mm"
            return formatter.string(from: next)
        }
    }

    private static func duration(minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}
