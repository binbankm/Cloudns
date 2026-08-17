import Foundation

/// 集中缓存的日期格式化器，避免在 SwiftUI 视图渲染与列表滑动中频繁创建 DateFormatter / ISO8601DateFormatter 导致的掉帧卡顿。
enum DateFormatters {
    
    // MARK: - ISO8601 Formatters
    
    /// 标准 ISO8601 格式化器（如 "2023-01-01T12:00:00Z"）
    nonisolated(unsafe) static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
    
    /// 支持毫秒的 ISO8601 格式化器（如 "2023-01-01T12:00:00.123456Z"）
    nonisolated(unsafe) static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    // MARK: - Display Formatters
    
    /// 中等日期 + 简短时间（如 "2023年10月1日 14:30" / "Oct 1, 2023 at 2:30 PM"）
    nonisolated static let mediumDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// 完整日期 + 中等时间（如 "2023年10月1日 14:30:00"）
    nonisolated static let fullDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
    
    /// 仅简短时间（如 "14:30" / "2:30 PM"）
    nonisolated static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    /// 仅日期（如 "2023年10月1日"）
    nonisolated static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// 时间戳/日志格式（如 "HH:mm:ss.SSS"）
    nonisolated static let logTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    /// "yyyy-MM-dd" 日期格式化器
    nonisolated static let yearMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    /// "yyyy-MM-dd HH:mm" 日期格式化器
    nonisolated static let yearMonthDayHourMinute: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
    
    // MARK: - Helper Methods
    
    /// 解析分析图表中的日期字符串（支持 ISO8601 或 "yyyy-MM-dd"）
    nonisolated static func parseChartDate(_ dateString: String) -> Date {
        if dateString.contains("T") {
            return parseISO8601(dateString) ?? Date()
        } else {
            return yearMonthDay.date(from: dateString) ?? Date()
        }
    }
    
    /// 将 ISO8601 字符串解析为 Date（优先尝试带微秒，其次尝试标准）
    nonisolated static func parseISO8601(_ string: String) -> Date? {
        if let date = iso8601WithFractionalSeconds.date(from: string) {
            return date
        }
        return iso8601.date(from: string)
    }
    
    /// 将 ISO8601 字符串格式化为用户友好的展示文本
    nonisolated static func formatISO8601ToDisplay(_ string: String, style: DateFormatter = mediumDateTime) -> String {
        guard let date = parseISO8601(string) else {
            return string
        }
        return style.string(from: date)
    }
    
    /// 将时间戳（毫秒）格式化为日志时间字符串
    nonisolated static func formatTimestampMs(_ timestampMs: Double) -> String {
        let date = Date(timeIntervalSince1970: timestampMs / 1000.0)
        return logTime.string(from: date)
    }
}
