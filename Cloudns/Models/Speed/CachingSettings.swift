import Foundation

// MARK: - Caching Settings Model (Codable, Sendable, Equatable)

public struct CachingSettings: Codable, Equatable, Sendable {
    public var cacheLevel: String
    public var browserTTL: Int
    public var alwaysOnline: Bool
    public var developmentMode: Bool

    public init(
        cacheLevel: String = "aggressive",
        browserTTL: Int = 14400,
        alwaysOnline: Bool = true,
        developmentMode: Bool = false
    ) {
        self.cacheLevel = cacheLevel
        self.browserTTL = browserTTL
        self.alwaysOnline = alwaysOnline
        self.developmentMode = developmentMode
    }
}
