import Foundation

// MARK: - Speed Settings Model (Codable, Sendable, Equatable)

public struct SpeedSettings: Codable, Equatable, Sendable {
    public var brotli: Bool
    public var rocketLoader: Bool
    public var earlyHints: Bool
    public var speedBrain: Bool
    public var fonts: Bool
    public var tieredCache: Bool
    public var polish: String

    public init(
        brotli: Bool = false,
        rocketLoader: Bool = false,
        earlyHints: Bool = false,
        speedBrain: Bool = false,
        fonts: Bool = false,
        tieredCache: Bool = false,
        polish: String = "off"
    ) {
        self.brotli = brotli
        self.rocketLoader = rocketLoader
        self.earlyHints = earlyHints
        self.speedBrain = speedBrain
        self.fonts = fonts
        self.tieredCache = tieredCache
        self.polish = polish
    }
}
