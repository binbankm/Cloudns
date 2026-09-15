import Foundation

// MARK: - Cloudflare User Model (Official GET /client/v4/user)

/// Strongly typed user profile model aligned with Cloudflare v4 REST API
public struct CloudflareUser: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let email: String
    public let username: String?
    public let firstName: String?
    public let lastName: String?
    public let telephone: String?
    public let country: String?
    public let zipcode: String?
    public let twoFactorAuthenticationEnabled: Bool?
    public let suspended: Bool?
    public let createdOn: String?
    public let modifiedOn: String?

    public init(
        id: String,
        email: String,
        username: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        telephone: String? = nil,
        country: String? = nil,
        zipcode: String? = nil,
        twoFactorAuthenticationEnabled: Bool? = nil,
        suspended: Bool? = nil,
        createdOn: String? = nil,
        modifiedOn: String? = nil
    ) {
        self.id = id
        self.email = email
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.telephone = telephone
        self.country = country
        self.zipcode = zipcode
        self.twoFactorAuthenticationEnabled = twoFactorAuthenticationEnabled
        self.suspended = suspended
        self.createdOn = createdOn
        self.modifiedOn = modifiedOn
    }

    enum CodingKeys: String, CodingKey {
        case id, email, username, telephone, country, zipcode, suspended
        case firstName = "first_name"
        case lastName = "last_name"
        case twoFactorAuthenticationEnabled = "two_factor_authentication_enabled"
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
    }

    /// User-friendly display title
    public var displayName: String {
        if let first = firstName, !first.isEmpty {
            if let last = lastName, !last.isEmpty {
                return "\(first) \(last)"
            }
            return first
        }
        if let username, !username.isEmpty {
            return username
        }
        return email
    }
}
