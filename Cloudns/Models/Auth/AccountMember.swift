import Foundation

// MARK: - Account Member & Role Models (Codable, Sendable, Equatable)

public struct AccountMember: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let user: AccountMemberUser
    public let status: String
    public let roles: [AccountRole]

    public init(id: String, user: AccountMemberUser, status: String, roles: [AccountRole]) {
        self.id = id
        self.user = user
        self.status = status
        self.roles = roles
    }
}

public struct AccountMemberUser: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let email: String
    public let firstName: String?
    public let lastName: String?
    public let twoFactorAuthenticationEnabled: Bool?

    enum CodingKeys: String, CodingKey {
        case id, email
        case firstName = "first_name"
        case lastName = "last_name"
        case twoFactorAuthenticationEnabled = "two_factor_authentication_enabled"
    }

    public init(id: String, email: String, firstName: String? = nil, lastName: String? = nil, twoFactorAuthenticationEnabled: Bool? = nil) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.twoFactorAuthenticationEnabled = twoFactorAuthenticationEnabled
    }
}

public struct AccountRole: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let permissions: [String]?

    public init(id: String, name: String, description: String? = nil, permissions: [String]? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.permissions = permissions
    }
}
