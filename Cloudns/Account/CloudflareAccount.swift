import Foundation

// MARK: - Cloudflare Account Model (Pure Global API Key)

public struct CloudflareAccount: Identifiable, Codable, Sendable, Equatable {
    /// Unique identifier for local isolation and keychain indexing
    public let id: String

    /// User-friendly alias name (e.g. "Personal Blog", "Company Production")
    public var name: String

    /// Cloudflare account registration email
    public let email: String

    /// Account creation date
    public let createdAt: Date

    public init(
        id: String = UUID().uuidString,
        name: String,
        email: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? email : name
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdAt = createdAt
    }
}
