import Foundation

/// 统一的 Cloudflare Zone Analytics 分析领域服务
final class AnalyticsService {
    static let shared = AnalyticsService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    /// 获取 Zone 基础 Analytics 数据（过去 24 小时或指定时间跨度）
    func getDashboardAnalytics(zoneTag: String, days: Int) async throws -> AnalyticsViewerData {
        let query: String
        
        if days == 1 {
            let formatter = ISO8601DateFormatter()
            let pastDate = Calendar.current.date(byAdding: .hour, value: -23, to: Date()) ?? Date()
            let dateString = formatter.string(from: pastDate)
            
            query = """
            query {
              viewer {
                zones(filter: { zoneTag: "\(zoneTag)" }) {
                  httpRequests1hGroups(limit: 100, filter: { datetime_gt: "\(dateString)" }, orderBy: [datetime_ASC]) {
                    dimensions {
                      datetime
                    }
                    sum {
                      requests
                      bytes
                      cachedRequests
                      cachedBytes
                    }
                  }
                  trafficByCountry1h: httpRequestsAdaptiveGroups(limit: 50, filter: { datetime_gt: "\(dateString)" }, orderBy: [count_DESC]) {
                    dimensions {
                      clientCountryName
                    }
                    count
                  }
                }
              }
            }
            """
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let pastDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            let dateString = formatter.string(from: pastDate)
            
            let isoFormatter = ISO8601DateFormatter()
            let mapPastDate = Calendar.current.date(byAdding: .hour, value: -23, to: Date()) ?? Date()
            let mapDateString = isoFormatter.string(from: mapPastDate)
            
            query = """
            query {
              viewer {
                zones(filter: { zoneTag: "\(zoneTag)" }) {
                  httpRequests1dGroups(limit: 100, filter: { date_gt: "\(dateString)" }, orderBy: [date_ASC]) {
                    dimensions {
                      date
                    }
                    sum {
                      requests
                      bytes
                      cachedRequests
                      cachedBytes
                    }
                  }
                  trafficByCountry1d: httpRequestsAdaptiveGroups(limit: 50, filter: { datetime_gt: "\(mapDateString)" }, orderBy: [count_DESC]) {
                    dimensions {
                      clientCountryName
                    }
                    count
                  }
                }
              }
            }
            """
        }
        
        let payload: [String: Any] = ["query": query]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "graphql", method: "POST", body: data)
        let rawData = try await client.performDataRequest(request)
        
        do {
            let decoded = try JSONDecoder().decode(GraphQLResponse<AnalyticsViewerData>.self, from: rawData)
            if let errors = decoded.errors, !errors.isEmpty, decoded.data == nil {
                throw APIError.cloudflareError(errors.first?.message ?? "GraphQL Query Failed")
            }
            guard let a = decoded.data else {
                throw APIError.cloudflareError("Analytics data not available.")
            }
            return a
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func fetchGraphQLAnalytics(zoneTag: String, days: Int) async throws -> AnalyticsViewerData {
        try await getDashboardAnalytics(zoneTag: zoneTag, days: days)
    }
    
    /// 获取 Worker / Pages 专属调用量与性能指标数据 (GraphQL workersInvocationsAdaptive)
    func getWorkerAnalytics(accountId: String, scriptName: String, days: Int) async throws -> [WorkerAnalyticsItem] {
        let formatter = ISO8601DateFormatter()
        let pastDate: Date
        if days == 1 {
            pastDate = Calendar.current.date(byAdding: .hour, value: -23, to: Date()) ?? Date()
        } else {
            pastDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        }
        let dateString = formatter.string(from: pastDate)
        
        let query = """
        query {
          viewer {
            accounts(filter: { accountTag: "\(accountId)" }) {
              workersInvocationsAdaptive(
                limit: 1000,
                filter: {
                  scriptName: "\(scriptName)",
                  datetime_gt: "\(dateString)"
                },
                orderBy: [datetime_ASC]
              ) {
                dimensions {
                  datetime
                  status
                  scriptName
                }
                sum {
                  requests
                  errors
                  subrequests
                }
                quantiles {
                  cpuTimeP50
                  cpuTimeP99
                  durationMsP50
                  durationMsP99
                }
              }
            }
          }
        }
        """
        
        let payload: [String: Any] = ["query": query]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "graphql", method: "POST", body: data)
        let rawData = try await client.performDataRequest(request)
        
        do {
            let decoded = try JSONDecoder().decode(GraphQLResponse<WorkerAnalyticsViewerData>.self, from: rawData)
            if let errors = decoded.errors, !errors.isEmpty, decoded.data == nil {
                throw APIError.cloudflareError(errors.first?.message ?? "GraphQL Query Failed")
            }
            let list = decoded.data?.viewer.accounts?.first?.workersInvocationsAdaptive ?? []
            return list
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
