import Foundation

/// Parses GTFS `YYYYMMDD` date codes into `Date` values pinned to a fixed timezone.
///
/// GTFS date codes (used by `calendar.txt`'s `start_date`/`end_date` and
/// `calendar_dates.txt`'s `date`) are timezone-less strings that describe a
/// service day in the transit agency's local timezone (Europe/Helsinki for
/// Föli). Parsing them with the device's local timezone would silently shift
/// the represented instant depending on where the app runs, so this parser
/// pins the timezone, locale, and calendar explicitly.
///
/// A plain `DateFormatter` is a mutable, non-`Sendable` reference type, so
/// sharing a single instance across concurrency domains (or recreating one on
/// every access) is either unsafe or wasteful. `Date.ParseStrategy` is a
/// `Sendable` value type, so a fresh, cheaply-constructed strategy per call is
/// both safe and fast.
enum GTFSDateParser {
    /// Parses a `YYYYMMDD` string into a `Date` representing midnight in
    /// Europe/Helsinki on that calendar day.
    ///
    /// - Parameter code: A GTFS date code, e.g. `"20260710"`.
    /// - Returns: The parsed `Date`, or `nil` if `code` isn't a valid
    ///   `YYYYMMDD` string.
    static func date(from code: String) -> Date? {
        // `Date.ParseStrategy` matching is greedy: without a strict length
        // check, a malformed code (wrong digit count) can still parse by
        // misaligning which digits become the year/month/day.
        guard code.count == 8, code.utf8.allSatisfy({ $0 >= UInt8(ascii: "0") && $0 <= UInt8(ascii: "9") }) else {
            return nil
        }

        var calendar = Foundation.Calendar(identifier: .gregorian)
        calendar.timeZone = helsinkiTimeZone
        calendar.locale = posixLocale

        let strategy = Date.ParseStrategy(
            format: "\(year: .padded(4))\(month: .twoDigits)\(day: .twoDigits)",
            locale: posixLocale,
            timeZone: helsinkiTimeZone,
            calendar: calendar
        )

        return try? Date(code, strategy: strategy)
    }

    private static let helsinkiTimeZone = TimeZone(identifier: "Europe/Helsinki")!
    private static let posixLocale = Locale(identifier: "en_US_POSIX")
}
