import Foundation
import SwiftUI
import Combine

@MainActor
public final class CacheManager: ObservableObject {
    public static let shared = CacheManager()
    
    @Published public private(set) var formattedCacheSize: String = "0 KB"
    @Published public private(set) var isCalculating: Bool = false
    
    private init() {}
    
    public func calculateCacheSize() async {
        isCalculating = true
        
        let sizeInBytes = await Task.detached(priority: .utility) { () -> Int64 in
            var totalBytes: Int64 = 0
            let fm = FileManager.default
            
            totalBytes += Int64(URLCache.shared.currentDiskUsage)
            totalBytes += Int64(URLCache.shared.currentMemoryUsage)
            
            if let cachesDir = fm.urls(for: .cachesDirectory, in: .userDomainMask).first {
                totalBytes += CacheManager.directorySize(at: cachesDir)
            }
            
            let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            totalBytes += CacheManager.directorySize(at: tmpDir)
            
            return totalBytes
        }.value
        
        self.formattedCacheSize = CacheManager.formatBytes(sizeInBytes)
        self.isCalculating = false
    }
    
    public func clearAllCaches() async {
        URLCache.shared.removeAllCachedResponses()
        
        await Task.detached(priority: .userInitiated) {
            let fm = FileManager.default
            let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            if let contents = try? fm.contentsOfDirectory(at: tmpDir, includingPropertiesForKeys: nil) {
                for fileURL in contents {
                    try? fm.removeItem(at: fileURL)
                }
            }
        }.value
        
        await SWRCacheStore.shared.clearAll()
        
        self.formattedCacheSize = "0 KB"
        
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
