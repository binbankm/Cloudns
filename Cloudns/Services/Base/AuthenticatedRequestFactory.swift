import Foundation

/// 统一的 Cloudflare API 认证请求构造工厂
/// 负责从安全 Keychain 获取凭证，并拼接标准 API BaseURL 与请求头
final class AuthenticatedRequestFactory: Sendable {
    static let shared = AuthenticatedRequestFactory()
    
    let baseURL = "https://api.cloudflare.com/client/v4"
    let serviceName = "com.cloudflare.api"
    
    private init() {}
    
    /// 构建带有 X-Auth-Email 和 X-Auth-Key 认证头部的标准 URLRequest
    func createAuthenticatedRequest(
        path: String,
        queryItems: [URLQueryItem]? = nil,
        method: String = "GET",
        body: Data? = nil,
        contentType: String = "application/json"
    ) throws -> URLRequest {
        let email = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
        guard !email.isEmpty, let apiKey = KeychainHelper.standard.readString(service: serviceName, account: email) else {
            throw APIError.unauthorized
        }
        
        let fullURLString = path.hasPrefix("http") ? path : "\(baseURL)\(path.hasPrefix("/") ? path : "/\(path)")"
        guard var components = URLComponents(string: fullURLString) else {
            throw APIError.invalidURL
        }
        
        if let queryItems = queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        if !contentType.isEmpty {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        request.setValue(email, forHTTPHeaderField: "X-Auth-Email")
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = body
        return request
    }
}
