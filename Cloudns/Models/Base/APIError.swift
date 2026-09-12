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
            String(localized: "Invalid API URL.")
        case let .networkError(message):
            String(localized: "Network Error: \(message)")
        case .unauthorized:
            String(localized: "Authentication failed. Please verify your Cloudflare API Token or Global Key in Settings.")
        case .invalidResponse:
            String(localized: "Invalid response from Cloudflare server.")
        case let .decodingError(message):
            String(localized: "Data formatting error: \(message)")
        case let .cloudflareError(message):
            message
        }
    }

    var failureReason: String? {
        switch self {
        case .invalidURL:
            String(localized: "The constructed URL was malformed or could not be parsed.")
        case let .networkError(message):
            message
        case .unauthorized:
            String(localized: "The API token or key provided was rejected or has expired.")
        case .invalidResponse:
            String(localized: "The server returned a non-standard HTTP status code or empty response body.")
        case let .decodingError(message):
            message
        case let .cloudflareError(message):
            message
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            String(localized: "Please check your endpoint settings and domain name format.")
        case .networkError:
            String(localized: "Please check your network connection and try again.")
        case .unauthorized:
            String(localized: "Please re-enter your API credentials in Account Settings.")
        case .invalidResponse:
            String(localized: "Please try again later or check Cloudflare Status.")
        case .decodingError:
            String(localized: "Please check for app updates to support the latest Cloudflare API schema.")
        case .cloudflareError:
            String(localized: "Please verify your input parameters and permissions.")
        }
    }

    static func fromCloudflareResponse(data: Data, statusCode: Int? = nil, defaultMessage: String = "API Request Failed") -> APIError {
        struct CFErrorResponse: Codable, Sendable {
            struct ErrorItem: Codable, Sendable {
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
                } else if bodyString.contains("<title>"), bodyString.contains("</title>") {
                    if let start = bodyString.range(of: "<title>"),
                       let end = bodyString.range(of: "</title>", range: start.upperBound ..< bodyString.endIndex) {
                        let title = String(bodyString[start.upperBound ..< end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
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

        struct CFErrorResponse: Codable, Sendable {
            struct ErrorItem: Codable, Sendable {
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
