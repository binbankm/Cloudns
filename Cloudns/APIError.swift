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
            return "Cloudflare Error: \(message)"
        }
    }
}
