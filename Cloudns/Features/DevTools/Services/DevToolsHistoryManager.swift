import SwiftUI
import Combine

/// DevTools 常用网络诊断工具的查询历史管理器
@MainActor
public final class DevToolsHistoryManager: ObservableObject {
    // MARK: - ToolType
    public enum ToolType: String, CaseIterable, Sendable {
        case dnsDig = "devtools_history_dns_dig"
        case ipLookup = "devtools_history_ip_lookup"
        case whois = "devtools_history_whois"
    }
    
    // MARK: - Properties
    public static let shared = DevToolsHistoryManager()
    
    @Published public private(set) var dnsHistory: [String] = []
    @Published public private(set) var ipHistory: [String] = []
    @Published public private(set) var whoisHistory: [String] = []
    
    private let maxHistoryCount = 8
    private let userDefaults: UserDefaults
    
    // MARK: - Lifecycle / Init
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadAllHistory()
    }
    
    // MARK: - Public Methods
    
    /// 获取指定工具的查询历史
    public func history(for tool: ToolType) -> [String] {
        switch tool {
        case .dnsDig: return dnsHistory
        case .ipLookup: return ipHistory
        case .whois: return whoisHistory
        }
    }
    
    /// 记录一条新查询（自动去重并置顶）
    public func recordQuery(_ query: String, for tool: ToolType) {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        var list = history(for: tool)
        list.removeAll { $0.caseInsensitiveCompare(clean) == .orderedSame }
        list.insert(clean, at: 0)
        
        if list.count > maxHistoryCount {
            list = Array(list.prefix(maxHistoryCount))
        }
        
        updateHistory(list, for: tool)
        saveHistory(list, for: tool)
    }
    
    /// 移除单条历史记录
    public func removeQuery(_ query: String, for tool: ToolType) {
        var list = history(for: tool)
        list.removeAll { $0 == query }
        updateHistory(list, for: tool)
        saveHistory(list, for: tool)
    }
    
    /// 清空指定工具的所有查询历史
    public func clearHistory(for tool: ToolType) {
        updateHistory([], for: tool)
        userDefaults.removeObject(forKey: tool.rawValue)
    }
    
    // MARK: - Private Methods
    
    private func updateHistory(_ list: [String], for tool: ToolType) {
        switch tool {
        case .dnsDig: dnsHistory = list
        case .ipLookup: ipHistory = list
        case .whois: whoisHistory = list
        }
    }
    
    private func saveHistory(_ list: [String], for tool: ToolType) {
        userDefaults.set(list, forKey: tool.rawValue)
    }
    
    private func loadAllHistory() {
        dnsHistory = userDefaults.stringArray(forKey: ToolType.dnsDig.rawValue) ?? []
        ipHistory = userDefaults.stringArray(forKey: ToolType.ipLookup.rawValue) ?? []
        whoisHistory = userDefaults.stringArray(forKey: ToolType.whois.rawValue) ?? []
    }
}
