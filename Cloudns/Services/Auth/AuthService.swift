import Foundation

/// Protocol defining Cloudflare authentication and account management service
protocol AuthServiceProtocol: Sendable {
    @discardableResult
    func verifyCredentials(email: String, apiKey: String) async throws -> [Zone]
    func getUserDetails(email: String, apiKey: String) async throws -> CloudflareUser
    func getCurrentUserDetails() async throws -> CloudflareUser
    func updateUserProfile(firstName: String?, lastName: String?, telephone: String?, country: String?, zipcode: String?) async throws -> CloudflareUser
    func getAccounts() async throws -> [Account]
    func getAccounts(email: String, apiKey: String) async throws -> [Account]
    func getAccountDetails(accountId: String) async throws -> Account
    func updateAccount(accountId: String, name: String) async throws -> Account
    func getAccountMembers(accountId: String) async throws -> [AccountMember]
    func inviteAccountMember(accountId: String, email: String, roleIds: [String]) async throws -> AccountMember
    func deleteAccountMember(accountId: String, memberId: String) async throws
}

/// Concrete domain service for Cloudflare authentication and account management
final class AuthService: AuthServiceProtocol {
    static let shared = AuthService()

    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared

    private init() {}

    /// Validates user email and Global API Key credentials by pinging zones
    @discardableResult
    func verifyCredentials(email: String, apiKey: String) async throws -> [Zone] {
        let request = try factory.createExplicitAuthenticatedRequest(
            email: email,
            apiKey: apiKey,
            path: "zones",
            queryItems: [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "per_page", value: "1")
            ]
        )
        let (zones, _): ([Zone]?, ResultInfo?) = try await client.performRequest(request)
        return zones ?? []
    }

    /// Fetches official Cloudflare user details using explicit credentials (GET /client/v4/user)
    func getUserDetails(email: String, apiKey: String) async throws -> CloudflareUser {
        let request = try factory.createExplicitAuthenticatedRequest(
            email: email,
            apiKey: apiKey,
            path: "user"
        )
        let (user, _): (CloudflareUser?, ResultInfo?) = try await client.performRequest(request)
        guard let user else {
            throw APIError.cloudflareError("Failed to load Cloudflare user details.")
        }
        return user
    }

    /// Fetches current active user details (GET /client/v4/user)
    func getCurrentUserDetails() async throws -> CloudflareUser {
        let request = try factory.createAuthenticatedRequest(path: "user")
        let (user, _): (CloudflareUser?, ResultInfo?) = try await client.performRequest(request)
        guard let user else {
            throw APIError.cloudflareError("Failed to load Cloudflare user details.")
        }
        return user
    }

    /// Updates current user profile details (PATCH /client/v4/user)
    func updateUserProfile(
        firstName: String?,
        lastName: String?,
        telephone: String?,
        country: String?,
        zipcode: String?
    ) async throws -> CloudflareUser {
        struct UpdateProfilePayload: Encodable, Sendable {
            let firstName: String?
            let lastName: String?
            let telephone: String?
            let country: String?
            let zipcode: String?

            enum CodingKeys: String, CodingKey {
                case firstName = "first_name"
                case lastName = "last_name"
                case telephone, country, zipcode
            }
        }

        let payload = UpdateProfilePayload(
            firstName: firstName,
            lastName: lastName,
            telephone: telephone,
            country: country,
            zipcode: zipcode
        )
        let body = try JSONEncoder().encode(payload)
        let request = try factory.createAuthenticatedRequest(
            path: "user",
            method: "PATCH",
            body: body
        )
        let (user, _): (CloudflareUser?, ResultInfo?) = try await client.performRequest(request)
        guard let user else {
            throw APIError.cloudflareError("Failed to update Cloudflare user profile.")
        }
        return user
    }

    /// Fetches all accounts associated with active credentials (GET /client/v4/accounts)
    func getAccounts() async throws -> [Account] {
        let request = try factory.createAuthenticatedRequest(path: "accounts")
        let (accounts, _): ([Account]?, ResultInfo?) = try await client.performRequest(request)
        return accounts ?? []
    }

    /// Fetches all accounts using explicit credentials during login (GET /client/v4/accounts)
    func getAccounts(email: String, apiKey: String) async throws -> [Account] {
        let request = try factory.createExplicitAuthenticatedRequest(
            email: email,
            apiKey: apiKey,
            path: "accounts"
        )
        let (accounts, _): ([Account]?, ResultInfo?) = try await client.performRequest(request)
        return accounts ?? []
    }

    /// Fetches specific account details (GET /client/v4/accounts/{account_id})
    func getAccountDetails(accountId: String) async throws -> Account {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)")
        let (account, _): (Account?, ResultInfo?) = try await client.performRequest(request)
        guard let account else {
            throw APIError.cloudflareError("Account details not found.")
        }
        return account
    }

    /// Updates account name (PUT /client/v4/accounts/{account_id})
    func updateAccount(accountId: String, name: String) async throws -> Account {
        struct UpdateAccountPayload: Encodable, Sendable {
            let name: String
        }
        let body = try JSONEncoder().encode(UpdateAccountPayload(name: name))
        let request = try factory.createAuthenticatedRequest(
            path: "accounts/\(accountId)",
            method: "PUT",
            body: body
        )
        let (account, _): (Account?, ResultInfo?) = try await client.performRequest(request)
        guard let account else {
            throw APIError.cloudflareError("Failed to update account.")
        }
        return account
    }

    /// Fetches account members (GET /client/v4/accounts/{account_id}/members)
    func getAccountMembers(accountId: String) async throws -> [AccountMember] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/members")
        let (members, _): ([AccountMember]?, ResultInfo?) = try await client.performRequest(request)
        return members ?? []
    }

    /// Invites a new member to the account (POST /client/v4/accounts/{account_id}/members)
    func inviteAccountMember(accountId: String, email: String, roleIds: [String]) async throws -> AccountMember {
        struct InvitePayload: Encodable, Sendable {
            let email: String
            let roles: [String]
            let status: String
        }
        let payload = InvitePayload(email: email, roles: roleIds, status: "pending")
        let body = try JSONEncoder().encode(payload)
        let request = try factory.createAuthenticatedRequest(
            path: "accounts/\(accountId)/members",
            method: "POST",
            body: body
        )
        let (member, _): (AccountMember?, ResultInfo?) = try await client.performRequest(request)
        guard let member else {
            throw APIError.cloudflareError("Failed to invite account member.")
        }
        return member
    }

    /// Removes a member from the account (DELETE /client/v4/accounts/{account_id}/members/{member_id})
    func deleteAccountMember(accountId: String, memberId: String) async throws {
        let request = try factory.createAuthenticatedRequest(
            path: "accounts/\(accountId)/members/\(memberId)",
            method: "DELETE"
        )
        _ = try await client.performDataRequest(request)
    }
}
