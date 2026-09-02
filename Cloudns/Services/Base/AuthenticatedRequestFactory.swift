import Foundation

/// Factory for constructing authenticated Cloudflare API requests
/// Retrieves credentials securely from Keychain and attaches API BaseURL and auth headers
final class AuthenticatedRequestFactory: Sendable {
    static let shared = AuthenticatedRequestFactory()
    
    let baseURL = "https://api.cloudflare.com/client/v4"
    let serviceName = AppStorageKey.keychainService
    
    private init() {}
    
    /// Builds standard URLRequest with X-Auth-Email and X-Auth-Key authentication headers
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
        return try createExplicitAuthenticatedRequest(
            email: email,
            apiKey: apiKey,
            path: path,
            queryItems: queryItems,
            method: method,
            body: body,
            contentType: contentType
        )
    }
    
    /// Builds URLRequest with explicit credentials for authentication verification
    func createExplicitAuthenticatedRequest(
        email: String,
        apiKey: String,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        method: String = "GET",
        body: Data? = nil,
        contentType: String = "application/json"
    ) throws -> URLRequest {
        guard !email.isEmpty, !apiKey.isEmpty else {
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
