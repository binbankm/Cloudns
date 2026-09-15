import Foundation

// MARK: - General Security Settings (Codable, Sendable, Equatable)

public struct SecuritySettings: Codable, Equatable, Sendable {
    public var securityLevel: String
    public var challengeTTL: Int
    public var browserCheck: Bool
    public var botFightMode: Bool
    public var botManagement: BotManagementConfig?

    public init(
        securityLevel: String = "medium",
        challengeTTL: Int = 1800,
        browserCheck: Bool = true,
        botFightMode: Bool = false,
        botManagement: BotManagementConfig? = nil
    ) {
        self.securityLevel = securityLevel
        self.challengeTTL = challengeTTL
        self.browserCheck = browserCheck
        self.botFightMode = botFightMode
        self.botManagement = botManagement
    }
}
