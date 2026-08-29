import Foundation

/// Cloudflare 登录认证与账户管理领域服务协议
protocol AuthServiceProtocol: Sendable {
    @discardableResult
    func verifyCredentials(email: String, apiKey: String) async throws -> [Zone]
    func verifyToken() async throws -> [Account]
    func getAccounts() async throws -> [Account]
}

/// 统一的 Cloudflare 登录认证与账户管理领域服务
final class AuthService: AuthServiceProtocol {
    static let shared = AuthService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    /// 显式校验用户输入的邮箱与 Global API Key 是否合法有效
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
    
    /// 验证当前凭证并获取关联的 Cloudflare 账户列表
    func verifyToken() async throws -> [Account] {
        try await getAccounts()
    }
    
    /// 获取当前凭证下的所有账户列表
    func getAccounts() async throws -> [Account] {
        let request = try factory.createAuthenticatedRequest(path: "accounts")
        let (accounts, _): ([Account]?, ResultInfo?) = try await client.performRequest(request)
        return accounts ?? []
    }
}
