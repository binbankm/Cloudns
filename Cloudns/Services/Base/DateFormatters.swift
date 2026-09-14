import Foundation

enum DateFormatters: Sendable {
    // MARK: - Modern ISO8601 Formatters

    static func formatISO8601(_ date: Date) -> String {
        date.ISO8601Format()
    }

    static func formatYearMonthDay(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone(secondsFromGMT: 0)
        return df.string(from: date)
    }

    static func formatHour(_ date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        return String(format: "%02d:00", hour)
    }

    static func parseISO8601(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if let date = try? Date(trimmed, strategy: .iso8601) {
            return date
        }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: trimmed) {
            return date
        }

        let isoStandard = ISO8601DateFormatter()
        if let date = isoStandard.date(from: trimmed) {
            return date
        }

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)

        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = df.date(from: trimmed) {
            return date
        }

        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = df.date(from: trimmed) {
            return date
        }

        df.dateFormat = "yyyy-MM-dd"
        if let date = df.date(from: trimmed) {
            return date
        }

        return nil
    }
}
