import Foundation

/// Protocol defining Cloudflare authentication and account management service
protocol AuthServiceProtocol: Sendable {
    @discardableResult
    func verifyCredentials(email: String, apiKey: String) async throws -> [Zone]
    func verifyToken() async throws -> [Account]
    func getAccounts() async throws -> [Account]
}

/// Concrete domain service for Cloudflare authentication and account management
final class AuthService: AuthServiceProtocol {
    static let shared = AuthService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    /// Validates user email and Global API Key credentials
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
    
    /// Verifies credentials and retrieves associated Cloudflare accounts
    func verifyToken() async throws -> [Account] {
        try await getAccounts()
    }
    
    /// Fetches all accounts associated with active credentials
    func getAccounts() async throws -> [Account] {
        let request = try factory.createAuthenticatedRequest(path: "accounts")
        let (accounts, _): ([Account]?, ResultInfo?) = try await client.performRequest(request)
        return accounts ?? []
    }
}
