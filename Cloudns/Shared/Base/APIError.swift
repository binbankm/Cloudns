import Foundation

enum APIError: Error, LocalizedError, Sendable {
    case invalidURL
    case networkError(String)
    case unauthorized
    case invalidResponse
    case decodingError(String)
    case cloudflareError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL."
        case .networkError(let message):
            return "Network Error: \(message)"
        case .unauthorized:
            return "Authentication failed. Please verify your Cloudflare API Token or Global Key in Settings."
        case .invalidResponse:
            return "Invalid response from Cloudflare server."
        case .decodingError(let message):
            return "Data formatting error: \(message)"
        case .cloudflareError(let message):
            return message
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidURL:
            return "The constructed URL was malformed or could not be parsed."
        case .networkError(let message):
            return message
        case .unauthorized:
            return "The API token or key provided was rejected or has expired."
        case .invalidResponse:
            return "The server returned a non-standard HTTP status code or empty response body."
        case .decodingError(let message):
            return message
        case .cloudflareError(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Please check your endpoint settings and domain name format."
        case .networkError:
            return "Please check your network connection and try again."
        case .unauthorized:
            return "Please re-enter your API credentials in Account Settings."
        case .invalidResponse:
            return "Please try again later or check Cloudflare Status."
        case .decodingError:
            return "Please check for app updates to support the latest Cloudflare API schema."
        case .cloudflareError:
            return "Please verify your input parameters and permissions."
        }
    }
    
    /// 便捷构造器，预先解析原始错误响应（支持 JSON 与 HTML 容错提取）
    static func fromCloudflareResponse(data: Data, statusCode: Int? = nil, defaultMessage: String = "API Request Failed") -> APIError {
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
        
        if let bodyString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !bodyString.isEmpty {
            // Check if response is HTML
            if bodyString.hasPrefix("<!DOCTYPE") || bodyString.lowercased().contains("<html") {
                if let status = statusCode {
                    return .cloudflareError("Cloudflare Gateway Error (HTTP \(status))")
                } else if bodyString.contains("<title>") && bodyString.contains("</title>") {
                    if let start = bodyString.range(of: "<title>"),
                       let end = bodyString.range(of: "</title>", range: start.upperBound..<bodyString.endIndex) {
                        let title = String(bodyString[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                        if !title.isEmpty {
                            return .cloudflareError(title)
                        }
                    }
                }
                return .cloudflareError(defaultMessage)
            }
            
            // Clean up if short text
            if bodyString.count <= 250 {
                return .cloudflareError(bodyString)
            } else {
                return .cloudflareError(String(bodyString.prefix(250)) + "...")
            }
        }
        
        if let status = statusCode {
            return .cloudflareError("\(defaultMessage) (HTTP \(status))")
        }
        return .cloudflareError(defaultMessage)
    }
    
    static func formatCloudflareError(_ rawMessage: String) -> String {
        guard let data = rawMessage.data(using: .utf8) else {
            if rawMessage.hasPrefix("<!DOCTYPE") || rawMessage.lowercased().contains("<html") {
                return "Cloudflare Gateway Error"
            }
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
        
        if rawMessage.hasPrefix("<!DOCTYPE") || rawMessage.lowercased().contains("<html") {
            return "Cloudflare Gateway Error"
        }
        
        return rawMessage
    }
}
