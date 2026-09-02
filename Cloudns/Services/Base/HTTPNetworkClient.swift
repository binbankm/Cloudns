import Foundation

/// High-performance HTTP network client infrastructure
/// Handles URLSession configuration, 15s timeout control, connection pooling, and response parsing
final class HTTPNetworkClient: Sendable {
    static let shared = HTTPNetworkClient()
    
    private let session: URLSession
    private let maxRetries: Int
    
    init(session: URLSession? = nil, maxRetries: Int = 3) {
        self.maxRetries = maxRetries
        if let session = session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            // 15-second strict timeout to prevent deadlock on slow/unstable networks
            config.timeoutIntervalForRequest = 15.0
            config.timeoutIntervalForResource = 30.0
            config.waitsForConnectivity = false
            config.httpMaximumConnectionsPerHost = 8
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: config)
        }
    }
    
    /// Executes generic API request and decodes CloudflareResponse with automatic HTTP 429 retry backoff
    func performRequest<T: Codable & Sendable>(_ request: URLRequest) async throws -> (T?, ResultInfo?) {
        let (data, httpResponse) = try await executeWithResilience(request)
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        do {
            let decoded = try JSONDecoder().decode(CloudflareResponse<T>.self, from: data)
            if decoded.success {
                return (decoded.result, decoded.resultInfo)
            } else {
                throw APIError.fromCloudflareResponse(data: data, statusCode: httpResponse.statusCode, defaultMessage: "Unknown Cloudflare API Error (HTTP \(httpResponse.statusCode))")
            }
        } catch let decodeError as DecodingError {
            if !(200...299).contains(httpResponse.statusCode) {
                throw APIError.fromCloudflareResponse(data: data, statusCode: httpResponse.statusCode, defaultMessage: "HTTP \(httpResponse.statusCode)")
            }
            throw APIError.decodingError(decodeError.localizedDescription)
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }
    
    /// Executes API request returning raw Data with automatic HTTP 429 retry backoff
    public func performDataRequest(_ request: URLRequest) async throws -> Data {
        let (data, httpResponse) = try await executeWithResilience(request)
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.fromCloudflareResponse(data: data, statusCode: httpResponse.statusCode, defaultMessage: "HTTP \(httpResponse.statusCode)")
        }
        return data
    }
    
    /// Executes raw HTTP request returning (Data, HTTPURLResponse) with automatic HTTP 429 retry backoff
    public func performRawRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        return try await executeWithResilience(request)
    }
    
    /// Resilient execution core: intercepts HTTP 429 and performs exponential jittered backoff based on Retry-After
    private func executeWithResilience(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var currentAttempt = 0
        
        while true {
            try Task.checkCancellation()
            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await session.data(for: request)
            } catch {
                if Task.isCancelled {
                    throw CancellationError()
                }
                throw APIError.networkError(error.localizedDescription)
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Check HTTP 429 (Rate Limit)
            if httpResponse.statusCode == 429 && currentAttempt < maxRetries {
                currentAttempt += 1
                let retryDelay: TimeInterval
                if let retryAfterHeader = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                   let seconds = TimeInterval(retryAfterHeader), seconds > 0 {
                    retryDelay = min(seconds, 10.0) // Max retry delay: 10s
                } else {
                    // Exponential Backoff with Jitter: 2^attempt * 0.5 + jitter (0.1 ~ 0.5s)
                    let base = pow(2.0, Double(currentAttempt)) * 0.5
                    let jitter = Double.random(in: 0.1...0.5)
                    retryDelay = min(base + jitter, 10.0)
                }
                
                try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                continue
            }
            
            return (data, httpResponse)
        }
    }
}
