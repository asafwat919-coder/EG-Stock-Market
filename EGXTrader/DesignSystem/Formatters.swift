import Foundation

/// Number and date formatting used across the app. Formatters are expensive to
/// create, so they are built once and reused.
enum Fmt {
    private static let cairoLocale = Locale(identifier: "en_EG")

    private static let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = cairoLocale
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    private static let integerFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = cairoLocale
        f.maximumFractionDigits = 0
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = MarketClock.cairo
        return f
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        f.timeZone = MarketClock.cairo
        return f
    }()

    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM ''yy"
        f.timeZone = MarketClock.cairo
        return f
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM, HH:mm"
        f.timeZone = MarketClock.cairo
        return f
    }()

    /// `1,234.56`
    static func price(_ value: Double) -> String {
        priceFormatter.string(from: NSNumber(value: value)) ?? "--"
    }

    /// `EGP 1,234.56`
    static func egp(_ value: Double) -> String {
        "EGP " + price(value)
    }

    /// `+1.25%` / `-0.40%`
    static func percent(_ value: Double, signed: Bool = true) -> String {
        let sign = signed && value > 0 ? "+" : ""
        return sign + String(format: "%.2f%%", value)
    }

    /// `+1.25` / `-0.40`
    static func change(_ value: Double) -> String {
        let sign = value > 0 ? "+" : ""
        return sign + price(value)
    }

    static func integer(_ value: Double) -> String {
        integerFormatter.string(from: NSNumber(value: value)) ?? "--"
    }

    /// Compact large numbers: `12.4K`, `3.2M`, `1.1B`.
    static func compact(_ value: Double) -> String {
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""
        switch absValue {
        case 1_000_000_000_000...: return sign + String(format: "%.2fT", absValue / 1_000_000_000_000)
        case 1_000_000_000...: return sign + String(format: "%.2fB", absValue / 1_000_000_000)
        case 1_000_000...: return sign + String(format: "%.2fM", absValue / 1_000_000)
        case 10_000...: return sign + String(format: "%.1fK", absValue / 1_000)
        default: return sign + integer(absValue)
        }
    }

    static func time(_ date: Date) -> String { timeFormatter.string(from: date) }
    static func day(_ date: Date) -> String { dayFormatter.string(from: date) }
    static func monthYear(_ date: Date) -> String { monthYearFormatter.string(from: date) }
    static func dateTime(_ date: Date) -> String { dateTimeFormatter.string(from: date) }
}
