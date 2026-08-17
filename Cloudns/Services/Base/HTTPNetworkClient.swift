import Foundation

/// 统一的高性能 HTTP 基础网络客户端
/// 负责 URLSession 配置、15s 超时控制、连接池管理与响应解析
final class HTTPNetworkClient {
    static let shared = HTTPNetworkClient()
    
    private let session: URLSession
    
    init(session: URLSession? = nil) {
        if let session = session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            // 15 秒严格超时时间，避免在弱网/断网环境下死锁阻塞
            config.timeoutIntervalForRequest = 15.0
            config.timeoutIntervalForResource = 30.0
            config.waitsForConnectivity = false
            config.httpMaximumConnectionsPerHost = 8
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: config)
        }
    }
    
    /// 执行泛型 API 请求并反序列化 CloudflareResponse 结构
    func performRequest<T: Codable>(_ request: URLRequest) async throws -> (T?, ResultInfo?) {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
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
            throw APIError.decodingError(decodeError)
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    /// 执行返回原始 Data 的请求（如二进制、文件流或纯文本）
    public func performDataRequest(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw APIError.unauthorized
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.fromCloudflareResponse(data: data, statusCode: httpResponse.statusCode, defaultMessage: "HTTP \(httpResponse.statusCode)")
        }
        return data
    }
    
    /// 执行原始 HTTP 请求并返回 (Data, HTTPURLResponse)
    public func performRawRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        return (data, httpResponse)
    }
}
