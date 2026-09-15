import Foundation

/// Protocol defining Cloudflare authentication and account management service
protocol AuthServiceProtocol: Sendable {
    @discardableResult
    func verifyCredentials(email: String, apiKey: String) async throws -> [Zone]
    func getUserDetails(email: String, apiKey: String) async throws -> CloudflareUser
    func getCurrentUserDetails() async throws -> CloudflareUser
    func getAccounts() async throws -> [Account]
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

    /// Fetches all accounts associated with active credentials (GET /client/v4/accounts)
    func getAccounts() async throws -> [Account] {
        let request = try factory.createAuthenticatedRequest(path: "accounts")
        let (accounts, _): ([Account]?, ResultInfo?) = try await client.performRequest(request)
        return accounts ?? []
    }
}
