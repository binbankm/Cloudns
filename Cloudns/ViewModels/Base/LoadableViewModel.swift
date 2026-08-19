import Foundation
import SwiftUI
import Combine

/// 统一的基础加载状态协议与类，规范所有 ViewModel 的加载、错误与刷新生命周期
@MainActor
public protocol LoadableViewModelProtocol: ObservableObject {
    var isLoading: Bool { get set }
    var hasFetchedData: Bool { get set }
    var errorMessage: String? { get set }
}

@MainActor
open class BaseLoadableViewModel: ObservableObject, LoadableViewModelProtocol {
    @Published public var isLoading: Bool = false
    @Published public var hasFetchedData: Bool = false
    @Published public var errorMessage: String?
    public var lastFetchTime: Date?
    
    /// 数据新鲜度判断：距离上次请求超过 180 秒（3 分钟）视为过期需要重新再验证
    public var isStale: Bool {
        guard let last = lastFetchTime else { return true }
        return Date().timeIntervalSince(last) > 180
    }
    
    public init() {}
    
    /// 统一异步任务执行包装器，自动处理 loading 状态与 error 捕获，任务结束必将 hasFetchedData 置为 true
    public func executeLoadingTask(
        clearError: Bool = true,
        action: () async throws -> Void
    ) async {
        isLoading = true
        if clearError {
            errorMessage = nil
        }
        
        do {
            try await action()
            self.lastFetchTime = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        hasFetchedData = true
        isLoading = false
    }
    
    /// 重置加载状态与时间戳
    public func resetLoadingState() {
        self.isLoading = false
        self.hasFetchedData = false
        self.errorMessage = nil
        self.lastFetchTime = nil
    }
    
    /// 统一 SWR（Stale-While-Revalidate）异步任务执行包装器：
    /// 1. [Stale] 0ms 瞬间尝试从缓存取出旧数据回调渲染，标记 hasFetchedData = true 消除骨架屏
    /// 2. [Revalidate] 后台静默并发向网络获取最新数据
    /// 3. [Update] 成功后回调最新数据，并自动写入 SWRCacheStore
    public func executeSWR<T: Codable & Sendable>(
        cacheKey: String,
        targetType: T.Type,
        onCached: @MainActor (T) -> Void,
        fetcher: @Sendable () async throws -> T,
        onFresh: @MainActor (T) -> Void
    ) async {
        let scopedKey = SWRCacheStore.accountScopedKey(cacheKey)
        
        // 1. [Stale] 0ms 从缓存恢复
        if let cached = await SWRCacheStore.shared.get(forKey: scopedKey, as: targetType) {
            onCached(cached)
            self.hasFetchedData = true
        } else if !self.hasFetchedData {
            self.isLoading = true
        }
        
        // 2. [Revalidate] 后台静默拉取
        do {
            let fresh = try await fetcher()
            // 3. [Update] 更新数据并落盘
            onFresh(fresh)
            self.hasFetchedData = true
            self.lastFetchTime = Date()
            self.errorMessage = nil
            await SWRCacheStore.shared.set(fresh, forKey: scopedKey)
        } catch {
            if !self.hasFetchedData {
                self.errorMessage = error.localizedDescription
            }
        }
        self.isLoading = false
    }
}

public typealias BaseViewModel = BaseLoadableViewModel
