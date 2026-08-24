import Foundation
import SwiftUI
import Combine

/// 统一的工业级本地缓存管理引擎
/// 负责跨层级计算（SWR、URLCache、CachesDirectory、tmp）与深度清理
@MainActor
public final class CacheManager: ObservableObject {
    public static let shared = CacheManager()
    
    @Published public private(set) var formattedCacheSize: String = "0 KB"
    @Published public private(set) var isCalculating: Bool = false
    
    private init() {}
    
    /// 异步计算全沙盒缓存总大小
    public func calculateCacheSize() async {
        isCalculating = true
        
        let sizeInBytes = await Task.detached(priority: .utility) { () -> Int64 in
            var totalBytes: Int64 = 0
            let fm = FileManager.default
            
            // 1. URLCache 占用
            totalBytes += Int64(URLCache.shared.currentDiskUsage)
            totalBytes += Int64(URLCache.shared.currentMemoryUsage)
            
            // 2. Caches 目录占用 (含 SWRCache)
            if let cachesDir = fm.urls(for: .cachesDirectory, in: .userDomainMask).first {
                totalBytes += CacheManager.directorySize(at: cachesDir)
            }
            
            // 3. tmp 临时目录占用
            let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            totalBytes += CacheManager.directorySize(at: tmpDir)
            
            return totalBytes
        }.value
        
        self.formattedCacheSize = CacheManager.formatBytes(sizeInBytes)
        self.isCalculating = false
    }
    
    /// 执行四层深度缓存清理并广播通知
    public func clearAllCaches() async {
        // 1. 清理系统网络响应缓存
        URLCache.shared.removeAllCachedResponses()
        
        // 2. 清理 tmp 目录子项
        await Task.detached(priority: .userInitiated) {
            let fm = FileManager.default
            let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            if let contents = try? fm.contentsOfDirectory(at: tmpDir, includingPropertiesForKeys: nil) {
                for fileURL in contents {
                    try? fm.removeItem(at: fileURL)
                }
            }
        }.value
        
        // 3. 清理并重建 SWR 双层持久化缓存目录
        await SWRCacheStore.shared.clearAll()
        
        // 4. 重置显示状态为 0 KB
        self.formattedCacheSize = "0 KB"
        
        // 5. 广播缓存已清理通知，促使内存 ViewModel 重置状态
        NotificationCenter.default.post(name: .localCachePurged, object: nil)
    }
    
    // MARK: - Private Helpers
    
    public nonisolated static func directorySize(at directory: URL) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                  let isDir = resourceValues.isDirectory, !isDir,
                  let size = resourceValues.fileSize else { continue }
            totalSize += Int64(size)
        }
        return totalSize
    }
    
    public nonisolated static func formatBytes(_ bytes: Int64) -> String {
        if bytes <= 0 { return "0 KB" }
        return ByteCountFormatters.format(bytes)
    }
}
