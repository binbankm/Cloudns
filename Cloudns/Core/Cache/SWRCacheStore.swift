import Foundation
import CryptoKit

/// 统一的工业级 SWR（Stale-While-Revalidate）双层缓存引擎
/// 采用 Swift Actor 隔离保证并发线程安全，结合内存 NSCache（0ms）与沙盒磁盘持久化
public actor SWRCacheStore {
    public static let shared = SWRCacheStore()
    
    private let memoryCache = NSCache<NSString, NSData>()
    private let diskCacheDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        // 配置内存缓存限制 (最多 150 个条目，最大 50MB 内存占用)
        memoryCache.countLimit = 150
        memoryCache.totalCostLimit = 50 * 1024 * 1024
        
        let fm = FileManager.default
        let cachesDir = fm.urls(for: .cachesDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
        let targetDir = cachesDir.appendingPathComponent("SWRCache", isDirectory: true)
        self.diskCacheDirectory = targetDir
        
        try? fm.createDirectory(at: targetDir, withIntermediateDirectories: true, attributes: nil)
    }
    
    /// 构建包含当前账户邮箱的多租户隔离 Cache Key
    public static func accountScopedKey(_ baseKey: String) -> String {
        let activeEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? "default"
        return "\(activeEmail)_\(baseKey)"
    }
    
    /// 获取确定性的安全磁盘文件路径（使用 SHA256 散列，杜绝超长路径与非法字符）
    private func diskFileURL(for key: String) -> URL {
        let hash = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
        return diskCacheDirectory.appendingPathComponent("swr_\(hash).json")
    }
    
    /// 读取缓存数据 (优先从内存 0ms 返回，未命中时回退到磁盘)
    public func get<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        let nsKey = key as NSString
        
        // 1. 内存高速缓存查询
        if let memData = memoryCache.object(forKey: nsKey) as Data? {
            if let decoded = try? decoder.decode(type, from: memData) {
                return decoded
            }
        }
        
        // 2. 磁盘沙盒缓存查询
        let fileURL = diskFileURL(for: key)
        guard let diskData = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        // 写入回内存加速下次访问
        memoryCache.setObject(diskData as NSData, forKey: nsKey)
        
        return try? decoder.decode(type, from: diskData)
    }
    
    /// 写入缓存数据 (同步更新内存，异步写入磁盘)
    public func set<T: Codable>(_ value: T, forKey key: String) {
        guard let data = try? encoder.encode(value) else { return }
        
        let nsKey = key as NSString
        memoryCache.setObject(data as NSData, forKey: nsKey, cost: data.count)
        
        let fileURL = diskFileURL(for: key)
        try? data.write(to: fileURL, options: .atomic)
    }
    
    /// 删除指定缓存 Key
    public func remove(forKey key: String) {
        let nsKey = key as NSString
        memoryCache.removeObject(forKey: nsKey)
        let fileURL = diskFileURL(for: key)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    /// 清空所有 SWR 缓存
    public func clearAll() {
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(at: diskCacheDirectory)
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true, attributes: nil)
    }
}
