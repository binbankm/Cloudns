import Foundation

// MARK: - Scrape Shield Privacy & Anti-Scraping Settings (Codable, Sendable, Equatable)

public struct ScrapeShieldSettings: Codable, Equatable, Sendable {
    public var emailObfuscation: Bool
    public var serverSideExcludes: Bool
    public var hotlinkProtection: Bool

    public init(
        emailObfuscation: Bool = true,
        serverSideExcludes: Bool = true,
        hotlinkProtection: Bool = false
    ) {
        self.emailObfuscation = emailObfuscation
        self.serverSideExcludes = serverSideExcludes
        self.hotlinkProtection = hotlinkProtection
    }
}
