import Foundation
import CryptoKit
#if canImport(UIKit)
import UIKit
#endif

public struct CacheMetadata: Sendable {
    public let timestamp: Date
    public let ttl: TimeInterval?
    
    public var isExpired: Bool {
        guard let ttl = ttl else { return false }
        return Date().timeIntervalSince(timestamp) > ttl
    }
}

private final class MemoryCacheHolder: @unchecked Sendable {
    let cache = NSCache<NSString, NSData>()
}

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
            queue: .main
        ) { [weak holder] _ in
            holder?.cache.removeAllObjects()
        }
    }
    
    public static func accountScopedKey(_ baseKey: String) -> String {
        let activeEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail)
            .flatMap { $0.isEmpty ? nil : $0 } ?? "default"
        return "\(activeEmail)_\(baseKey)"
    }
    
    private func diskFileURL(for key: String) -> URL {
        let hash = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
        return diskCacheDirectory.appendingPathComponent("swr_\(hash).json")
    }
    
    public func get<T: Codable & Sendable>(forKey key: String, as type: T.Type, ignoreExpiration: Bool = true) -> T? {
        let nsKey = key as NSString
        
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
        
        let fileURL = diskFileURL(for: key)
        guard let diskData = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
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
    
    public func set<T: Codable & Sendable>(_ value: T, forKey key: String, ttl: TimeInterval? = nil) {
        let envelope = CacheEnvelope(value: value, timestamp: Date(), ttl: ttl)
        guard let data = try? encoder.encode(envelope) else { return }
        
        let nsKey = key as NSString
        memoryCache.setObject(data as NSData, forKey: nsKey, cost: data.count)
        
        let fileURL = diskFileURL(for: key)
        try? data.write(to: fileURL, options: .atomic)
    }
    
    public func setMemoryOnly<T: Codable & Sendable>(_ value: T, forKey key: String, ttl: TimeInterval? = nil) {
        let envelope = CacheEnvelope(value: value, timestamp: Date(), ttl: ttl)
        guard let data = try? encoder.encode(envelope) else { return }
        
        let nsKey = key as NSString
        memoryCache.setObject(data as NSData, forKey: nsKey, cost: data.count)
    }
    
    public func remove(forKey key: String) {
        let nsKey = key as NSString
        memoryCache.removeObject(forKey: nsKey)
        let fileURL = diskFileURL(for: key)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    public func clearAll() {
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(at: diskCacheDirectory)
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true, attributes: nil)
    }
}
