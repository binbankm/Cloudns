import Foundation
import CryptoKit
#if canImport(UIKit)
import UIKit
#endif

/// 缓存元数据
public struct CacheMetadata: Sendable {
    public let timestamp: Date
    public let ttl: TimeInterval?
    
    public var isExpired: Bool {
        guard let ttl = ttl else { return false }
        return Date().timeIntervalSince(timestamp) > ttl
    }
}

/// 内存缓存安全持有者
private final class MemoryCacheHolder: @unchecked Sendable {
    let cache = NSCache<NSString, NSData>()
}

/// 统一的工业级 SWR（Stale-While-Revalidate）双层缓存引擎
/// 采用 Swift Actor 隔离保证并发线程安全，结合内存 NSCache（0ms）与沙盒磁盘持久化
public actor SWRCacheStore {
    public static let shared = SWRCacheStore()
    
    private let memoryCacheHolder = MemoryCacheHolder()
    private var memoryCache: NSCache<NSString, NSData> { memoryCacheHolder.cache }
    private let diskCacheDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private struct CacheEnvelope<T: Codable & Sendable>: Codable, Sendable {
        let value: T
        let timestamp: Date
        let ttl: TimeInterval?
    }
    
    private init() {
        let holder = memoryCacheHolder
        // 配置内存缓存限制 (最多 150 个条目，最大 50MB 内存占用)
        holder.cache.countLimit = 150
        holder.cache.totalCostLimit = 50 * 1024 * 1024
        
        let fm = FileManager.default
        let cachesDir = fm.urls(for: .cachesDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
        let targetDir = cachesDir.appendingPathComponent("SWRCache", isDirectory: true)
        self.diskCacheDirectory = targetDir
        
        try? fm.createDirectory(at: targetDir, withIntermediateDirectories: true, attributes: nil)
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak holder] _ in
            holder?.cache.removeAllObjects()
        }
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
    
    /// 读取缓存数据 (优先从内存 0ms 返回，未命中时回退到磁盘，支持 TTL 策略)
    public func get<T: Codable & Sendable>(forKey key: String, as type: T.Type, ignoreExpiration: Bool = true) -> T? {
        let nsKey = key as NSString
        
        // 1. 内存高速缓存查询
        if let memData = memoryCache.object(forKey: nsKey) as Data? {
            if let envelope = try? decoder.decode(CacheEnvelope<T>.self, from: memData) {
                if !ignoreExpiration, let ttl = envelope.ttl {
                    let isExpired = Date().timeIntervalSince(envelope.timestamp) > ttl
                    if isExpired {
                        remove(forKey: key)
                        return nil
                    }
                }
                return envelope.value
            } else if let raw = try? decoder.decode(type, from: memData) {
                return raw
            }
        }
        
        // 2. 磁盘沙盒缓存查询
        let fileURL = diskFileURL(for: key)
        guard let diskData = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        // 写入回内存加速下次访问
        memoryCache.setObject(diskData as NSData, forKey: nsKey)
        
        if let envelope = try? decoder.decode(CacheEnvelope<T>.self, from: diskData) {
            if !ignoreExpiration, let ttl = envelope.ttl {
                let isExpired = Date().timeIntervalSince(envelope.timestamp) > ttl
                if isExpired {
                    remove(forKey: key)
                    return nil
                }
            }
            return envelope.value
        } else if let raw = try? decoder.decode(type, from: diskData) {
            return raw
        }
        
        return nil
    }
    
    /// 获取缓存数据及其元数据（时间戳与 TTL 状态）
    public func getWithMetadata<T: Codable & Sendable>(forKey key: String, as type: T.Type) -> (value: T, metadata: CacheMetadata)? {
        let nsKey = key as NSString
        var targetData: Data? = memoryCache.object(forKey: nsKey) as Data?
        
        if targetData == nil {
            let fileURL = diskFileURL(for: key)
            if let diskData = try? Data(contentsOf: fileURL) {
                targetData = diskData
                memoryCache.setObject(diskData as NSData, forKey: nsKey)
            }
        }
        
        guard let data = targetData else { return nil }
        
        if let envelope = try? decoder.decode(CacheEnvelope<T>.self, from: data) {
            let meta = CacheMetadata(timestamp: envelope.timestamp, ttl: envelope.ttl)
            return (envelope.value, meta)
        } else if let raw = try? decoder.decode(type, from: data) {
            let meta = CacheMetadata(timestamp: Date(), ttl: nil)
            return (raw, meta)
        }
        
        return nil
    }
    
    /// 写入缓存数据 (支持指定可选 TTL 过期时间，单位秒)
    public func set<T: Codable & Sendable>(_ value: T, forKey key: String, ttl: TimeInterval? = nil) {
        let envelope = CacheEnvelope(value: value, timestamp: Date(), ttl: ttl)
        guard let data = try? encoder.encode(envelope) else { return }
        
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
