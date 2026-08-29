import Foundation

/// Cloudflare 官方系统可用性与组件运行状态服务协议
protocol CloudflareStatusServiceProtocol: Sendable {
    func fetchCloudflareStatus() async throws -> CFStatusSummary
}

/// 统一的 Cloudflare 官方系统运行状态服务
final class CloudflareStatusService: CloudflareStatusServiceProtocol {
    static let shared = CloudflareStatusService()
    
    private init() {}
    
    func fetchCloudflareStatus() async throws -> CFStatusSummary {
        guard let url = URL(string: "https://www.cloudflarestatus.com/api/v2/summary.json") else {
            throw APIError.invalidURL
        }
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        let (data, _) = try await session.data(from: url)
        let summary = try JSONDecoder().decode(CFStatusSummary.self, from: data)
        return summary
    }
}
