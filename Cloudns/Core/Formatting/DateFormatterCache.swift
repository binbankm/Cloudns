import Foundation

enum DateFormatters: Sendable {
    // MARK: - Modern ISO8601 Formatters

    static func formatISO8601(_ date: Date) -> String {
        date.ISO8601Format()
    }

    // MARK: - Standard Chart Formatters (12-Language Adaptive & DevOps Standards)

    static var chartXAxisHourly: Date.FormatStyle {
        .dateTime.locale(currentAppLocale).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)
    }

    static var chartXAxisDaily: Date.FormatStyle {
        .dateTime.locale(currentAppLocale).month(.abbreviated).day()
    }

    static func formatChartDetailDate(_ date: Date, isHourly: Bool) -> String {
        let loc = currentAppLocale
        if isHourly {
            return date.formatted(.dateTime.locale(loc).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
        } else {
            return date.formatted(.dateTime.locale(loc).month(.abbreviated).day().weekday(.short))
        }
    }

    // MARK: - Display Formatters (Thread-Safe Swift FormatStyle)

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

    static func parseChartDate(_ dateString: String) -> Date {
        if dateString.contains("T") {
            return parseISO8601(dateString) ?? Date()
        } else {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd"
            df.timeZone = TimeZone(secondsFromGMT: 0)
            return df.date(from: dateString) ?? Date()
        }
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

    static var currentAppLocale: Locale {
        let appLang = UserDefaults.standard.string(forKey: AppStorageKey.appLanguage) ?? "system"
        if appLang != "system", !appLang.isEmpty {
            return Locale(identifier: appLang)
        }
        if let preferred = Bundle.main.preferredLocalizations.first {
            return Locale(identifier: preferred)
        }
        return Locale.autoupdatingCurrent
    }

    enum DisplayStyle: Sendable {
        case medium
        case full
        case timeOnly
        case dateOnly
    }

    static func formatISO8601ToDisplay(_ string: String, style: DisplayStyle = .medium) -> String {
        guard let date = parseISO8601(string) else {
            return string
        }
        let loc = currentAppLocale
        switch style {
        case .dateOnly:
            return date.formatted(.dateTime.locale(loc).year().month(.abbreviated).day())
        case .full:
            return date.formatted(.dateTime.locale(loc).year().month(.abbreviated).day().hour().minute().second())
        case .timeOnly:
            return date.formatted(.dateTime.locale(loc).hour().minute())
        case .medium:
            return date.formatted(.dateTime.locale(loc).year().month(.abbreviated).day().hour().minute())
        }
    }

    static func formatRelative(from string: String) -> String {
        guard let date = parseISO8601(string) else {
            return string.prefix(10).description
        }
        return date.formatted(.relative(presentation: .named).locale(currentAppLocale))
    }

    static func formatTimestampMs(_ timestampMs: Double) -> String {
        let date = Date(timeIntervalSince1970: timestampMs / 1000.0)
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss.SSS"
        return df.string(from: date)
    }

    static func formatLocalDiagnosticTimestamp(_ date: Date = Date()) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        df.dateFormat = "yyyy-MM-dd HH:mm:ss (zzz)"
        return df.string(from: date)
    }
}

// MARK: - Date Locale-Aware Formatting Extension

public extension Date {
    /// Formats the date using the current user-selected in-app locale
    func displayFormatted(date: Date.FormatStyle.DateStyle = .abbreviated, time: Date.FormatStyle.TimeStyle = .omitted) -> String {
        formatted(Date.FormatStyle(date: date, time: time).locale(DateFormatters.currentAppLocale))
    }

    /// Formats relative date (e.g. "2 hours ago", "2小时前", "vor 2 Stunden") using the current user-selected in-app locale
    func relativeFormatted(presentation: Date.RelativeFormatStyle.Presentation = .named) -> String {
        formatted(Date.RelativeFormatStyle(presentation: presentation).locale(DateFormatters.currentAppLocale))
    }
}

enum MetricFormatters {
    static func compactNumber(_ num: some BinaryInteger) -> String {
        compactNumber(Double(num))
    }

    static func compactNumber(_ val: Double) -> String {
        if val >= 1_000_000_000 {
            return "\((val / 1_000_000_000).formatted(.number.precision(.fractionLength(2))))B"
        } else if val >= 1_000_000 {
            return "\((val / 1_000_000).formatted(.number.precision(.fractionLength(2))))M"
        } else if val >= 1000 {
            return "\((val / 1000).formatted(.number.precision(.fractionLength(1))))K"
        }
        return val.formatted(.number.precision(.fractionLength(0)))
    }
}

enum ByteCountFormatters {
    static func format(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    static func format(_ bytes: some BinaryInteger) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
