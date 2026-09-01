import Foundation

/// 集中缓存的日期格式化器，避免在 SwiftUI 视图渲染与列表滑动中频繁创建 DateFormatter / ISO8601DateFormatter 导致的掉帧卡顿。
enum DateFormatters {
    
    // MARK: - Modern ISO8601 Formatters
    
    /// 标准 ISO8601 格式化器单例
    nonisolated(unsafe) static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
    
    /// 将 Date 格式化为标准 ISO8601 字符串（如 "2023-01-01T12:00:00Z"）
    static func formatISO8601(_ date: Date) -> String {
        date.ISO8601Format()
    }
    
    // MARK: - Standard Chart Formatters (12-Language Adaptive & DevOps Standards)
    
    /// 适用于图表 X 轴 24h 走势刻度（严格 24 小时制且补零，如 "08:00", "14:00"）
    static let chartXAxisHourly: Date.FormatStyle = .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)
    
    /// 适用于图表 X 轴多天刻度（自适应 12 种语言月日缩写，如 中文"9月1日", 英文"Sep 1", 德文"1. Sept."）
    static let chartXAxisDaily: Date.FormatStyle = .dateTime.month(.abbreviated).day()
    
    /// 图表交互选中（Scrubbing）详情时间格式化：24h 模式下显示 "HH:mm"，多天模式下显示带星期缩写（如 "9月1日 周二" / "Tue, Sep 1"）
    static func formatChartDetailDate(_ date: Date, isHourly: Bool) -> String {
        let loc = currentAppLocale
        if isHourly {
            return date.formatted(.dateTime.locale(loc).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
        } else {
            return date.formatted(.dateTime.locale(loc).month(.abbreviated).day().weekday(.short))
        }
    }
    
    // MARK: - Display Formatters
    
    /// 中等日期 + 简短时间（如 "2023年10月1日 14:30" / "Oct 1, 2023 at 2:30 PM"）
    static let mediumDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// 完整日期 + 中等时间（如 "2023年10月1日 14:30:00"）
    static let fullDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
    
    /// 仅简短时间（如 "14:30" / "2:30 PM"）
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// 仅小时格式化器（如 "14:00"）
    static let hourOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:00"
        return formatter
    }()
    
    /// 格式化为小时简短字符串（如 "14:00"）
    static func formatHour(_ date: Date) -> String {
        hourOnly.string(from: date)
    }
    
    /// 仅日期（如 "2023年10月1日"）
    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// 时间戳/日志格式（如 "HH:mm:ss.SSS"）
    static let logTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    /// "yyyy-MM-dd" 日期格式化器
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
    
    /// 解析分析图表中的日期字符串（支持 ISO8601 或 "yyyy-MM-dd"）
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

    /// 将 ISO8601 字符串解析为 Date（优先尝试带毫秒/纳秒，其次尝试值类型 strategy，再次尝试无时区回退）
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
    
    /// 当前 App 实际生效的本地化语言 Locale（动态响应系统语言、应用独立语言设置）
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
    
    /// 将 ISO8601 字符串格式化为用户友好的展示文本（使用 Apple 现代 Foundation 格式化，严格绑定当前 App 语言）
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
    
    /// 将 ISO8601 字符串格式化为相对时间（如 "2 hours ago" 或 "2小时前"）
    static func formatRelative(from string: String) -> String {
        guard let date = parseISO8601(string) else {
            return string.prefix(10).description
        }
        return date.formatted(.relative(presentation: .named).locale(currentAppLocale))
    }
    
    /// 将时间戳（毫秒）格式化为日志时间字符串
    static func formatTimestampMs(_ timestampMs: Double) -> String {
        let date = Date(timeIntervalSince1970: timestampMs / 1000.0)
        return logTime.string(from: date)
    }
    
    /// 将日期格式化为本地时区的诊断日志时间字符串（如 "2026-08-17 18:42:38 (GMT+8)"）
    static func formatLocalDiagnosticTimestamp(_ date: Date = Date()) -> String {
        return localDiagnosticFormatter.string(from: date)
    }
}

/// 集中提供的度量数字紧凑格式化器（如 1.2K, 3.4M, 5.6B）
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

/// 集中提供的字节/大小格式化器，使用 Foundation 线程安全静态方法
enum ByteCountFormatters {
    static func format(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
    
    static func format<T: BinaryInteger>(_ bytes: T) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
