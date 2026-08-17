import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case unauthorized
    case invalidResponse
    case decodingError(Error)
    case cloudflareError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL."
        case .networkError(let error):
            return "Network Error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized. Please check your Global API Key and Email."
        case .invalidResponse:
            return "Invalid response from Cloudflare."
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .cloudflareError(let message):
            return message
        }
    }
    
    /// 便捷构造器，预先解析原始错误响应
    static func fromCloudflareResponse(data: Data, defaultMessage: String = "API Request Failed") -> APIError {
        struct CFErrorResponse: Codable {
            struct ErrorItem: Codable {
                let code: Int?
                let message: String?
            }
            let errors: [ErrorItem]?
            let messages: [String]?
        }
        
        if let decoded = try? JSONDecoder().decode(CFErrorResponse.self, from: data),
           let errors = decoded.errors, !errors.isEmpty {
            let messages = errors.compactMap { err -> String? in
                guard let msg = err.message, !msg.isEmpty else { return nil }
                if let code = err.code {
                    return "\(msg) (Code \(code))"
                }
                return msg
            }
            if !messages.isEmpty {
                return .cloudflareError(messages.joined(separator: "\n"))
            }
        }
        
        if let bodyString = String(data: data, encoding: .utf8), !bodyString.isEmpty {
            return .cloudflareError(bodyString)
        }
        return .cloudflareError(defaultMessage)
    }
    
    static func formatCloudflareError(_ rawMessage: String) -> String {
        guard let data = rawMessage.data(using: .utf8) else {
            return rawMessage
        }
        
        struct CFErrorResponse: Codable {
            struct ErrorItem: Codable {
                let code: Int?
                let message: String?
            }
            let errors: [ErrorItem]?
            let messages: [String]?
        }
        
        if let decoded = try? JSONDecoder().decode(CFErrorResponse.self, from: data),
           let errors = decoded.errors, !errors.isEmpty {
            let messages = errors.compactMap { err -> String? in
                guard let msg = err.message, !msg.isEmpty else { return nil }
                if let code = err.code {
                    return "\(msg) (Code \(code))"
                }
                return msg
            }
            if !messages.isEmpty {
                return messages.joined(separator: "\n")
            }
        }
        
        return rawMessage
    }
}
