import Foundation

enum DateFormatters {
    
    // MARK: - Modern ISO8601 Formatters
    
    nonisolated(unsafe) static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
    
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
    
    // MARK: - Display Formatters
    
    static let mediumDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let fullDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
    
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let hourOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:00"
        return formatter
    }()
    
    static func formatHour(_ date: Date) -> String {
        hourOnly.string(from: date)
    }
    
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let logTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    static let yearMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    private static let iso8601FallbackT: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
    
    private static let iso8601FallbackSpace: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    private static let localDiagnosticFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss (zzz)"
        return formatter
    }()

    // MARK: - Helper Methods
    
    static func parseChartDate(_ dateString: String) -> Date {
        if dateString.contains("T") {
            return parseISO8601(dateString) ?? Date()
        } else {
            return yearMonthDay.date(from: dateString) ?? Date()
        }
    }
    
    private nonisolated(unsafe) static let iso8601FractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func parseISO8601(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if let date = iso8601FractionalFormatter.date(from: trimmed) {
            return date
        }
        if let date = try? Date(trimmed, strategy: .iso8601) {
            return date
        }
        if let date = iso8601FallbackT.date(from: trimmed) {
            return date
        }
        if let date = iso8601FallbackSpace.date(from: trimmed) {
            return date
        }
        if let date = yearMonthDay.date(from: trimmed) {
            return date
        }
        return nil
    }
    
    static var currentAppLocale: Locale {
        let appLang = UserDefaults.standard.string(forKey: AppStorageKey.appLanguage) ?? "system"
        if appLang != "system" && !appLang.isEmpty {
            return Locale(identifier: appLang)
        }
        if let preferred = Bundle.main.preferredLocalizations.first {
            return Locale(identifier: preferred)
        }
        return Locale.autoupdatingCurrent
    }
    
    static func formatISO8601ToDisplay(_ string: String, style: DateFormatter = mediumDateTime) -> String {
        guard let date = parseISO8601(string) else {
            return string
        }
        let loc = currentAppLocale
        if style === dateOnly {
            return date.formatted(.dateTime.locale(loc).year().month(.abbreviated).day())
        } else if style === fullDateTime {
            return date.formatted(.dateTime.locale(loc).year().month(.abbreviated).day().hour().minute().second())
        } else if style === timeOnly {
            return date.formatted(.dateTime.locale(loc).hour().minute())
        } else {
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
        return logTime.string(from: date)
    }
    
    static func formatLocalDiagnosticTimestamp(_ date: Date = Date()) -> String {
        return localDiagnosticFormatter.string(from: date)
    }
}

// MARK: - Date Locale-Aware Formatting Extension

public extension Date {
    /// Formats the date using the current user-selected in-app locale
    func displayFormatted(date: Date.FormatStyle.DateStyle = .abbreviated, time: Date.FormatStyle.TimeStyle = .omitted) -> String {
        self.formatted(Date.FormatStyle(date: date, time: time).locale(DateFormatters.currentAppLocale))
    }
    
    /// Formats relative date (e.g. "2 hours ago", "2小时前", "vor 2 Stunden") using the current user-selected in-app locale
    func relativeFormatted(presentation: Date.RelativeFormatStyle.Presentation = .named) -> String {
        self.formatted(Date.RelativeFormatStyle(presentation: presentation).locale(DateFormatters.currentAppLocale))
    }
}

enum MetricFormatters {
    static func compactNumber<T: BinaryInteger>(_ num: T) -> String {
        compactNumber(Double(num))
    }
    
    static func compactNumber(_ val: Double) -> String {
        if val >= 1_000_000_000 {
            return "\((val / 1_000_000_000).formatted(.number.precision(.fractionLength(2))))B"
        } else if val >= 1_000_000 {
            return "\((val / 1_000_000).formatted(.number.precision(.fractionLength(2))))M"
        } else if val >= 1_000 {
            return "\((val / 1_000).formatted(.number.precision(.fractionLength(1))))K"
        }
        return val.formatted(.number.precision(.fractionLength(0)))
    }
}

enum ByteCountFormatters {
    static func format(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
    
    static func format<T: BinaryInteger>(_ bytes: T) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
