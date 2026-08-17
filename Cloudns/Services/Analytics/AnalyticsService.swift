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
            let pastDate = Calendar.current.date(byAdding: .hour, value: -24, to: Date()) ?? Date()
            let dateString = DateFormatters.iso8601.string(from: pastDate)
            
            query = """
            query {
              viewer {
                zones(filter: { zoneTag: "\(zoneTag)" }) {
                  httpRequests1hGroups(limit: 100, filter: { datetime_geq: "\(dateString)" }, orderBy: [datetime_ASC]) {
                    dimensions {
                      datetime
                    }
                    sum {
                      requests
                      bytes
                      cachedRequests
                      cachedBytes
                      threats
                      countryMap {
                        clientCountryName
                        requests
                        threats
                        bytes
                      }
                    }
                  }
                }
              }
            }
            """
        } else {
            let pastDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            let dateString = DateFormatters.yearMonthDay.string(from: pastDate)
            
            query = """
            query {
              viewer {
                zones(filter: { zoneTag: "\(zoneTag)" }) {
                  httpRequests1dGroups(limit: 100, filter: { date_geq: "\(dateString)" }, orderBy: [date_ASC]) {
                    dimensions {
                      date
                    }
                    sum {
                      requests
                      bytes
                      cachedRequests
                      cachedBytes
                      threats
                      countryMap {
                        clientCountryName
                        requests
                        threats
                        bytes
                      }
                    }
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
    
    /// 获取 Worker 专属调用量与性能指标数据 (GraphQL workersInvocationsAdaptive)
    func getWorkerAnalytics(accountId: String, scriptName: String, days: Int) async throws -> [WorkerAnalyticsItem] {
        let pastDate: Date
        if days == 1 {
            pastDate = Calendar.current.date(byAdding: .hour, value: -24, to: Date()) ?? Date()
        } else {
            pastDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        }
        let startDateString = DateFormatters.iso8601.string(from: pastDate)
        let endDateString = DateFormatters.iso8601.string(from: Date())
        
        let dimension = (days == 1) ? "datetimeHour" : "date"
        let orderBy = (days == 1) ? "datetimeHour_ASC" : "date_ASC"
        
        let query = """
        query {
          viewer {
            accounts(filter: { accountTag: "\(accountId)" }) {
              series: workersInvocationsAdaptive(
                limit: 1000,
                filter: {
                  scriptName: "\(scriptName)",
                  datetime_geq: "\(startDateString)",
                  datetime_leq: "\(endDateString)"
                },
                orderBy: [\(orderBy)]
              ) {
                dimensions {
                  \(dimension)
                }
                sum {
                  requests
                  errors
                  subrequests
                }
              }
              summary: workersInvocationsAdaptive(
                limit: 1000,
                filter: {
                  scriptName: "\(scriptName)",
                  datetime_geq: "\(startDateString)",
                  datetime_leq: "\(endDateString)"
                }
              ) {
                sum {
                  requests
                  errors
                  subrequests
                }
                quantiles {
                  cpuTimeP50
                  cpuTimeP99
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
            let firstAccount = decoded.data?.viewer.accounts?.first
            let series = firstAccount?.series ?? firstAccount?.workersInvocationsAdaptive ?? []
            let quantiles = firstAccount?.summary?.first?.quantiles
            
            // Attach summary quantiles to series items if needed
            if let quantiles, !series.isEmpty {
                return series.map { item in
                    WorkerAnalyticsItem(
                        dimensions: item.dimensions,
                        sum: item.sum,
                        quantiles: quantiles
                    )
                }
            }
            return series
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    /// 获取 Pages Functions 专属调用量与性能指标数据 (GraphQL pagesFunctions / workersInvocations)
    func getPagesAnalytics(accountId: String, projectName: String, days: Int) async throws -> [WorkerAnalyticsItem] {
        // First try standard workersInvocationsAdaptive with scriptName
        let items = try? await getWorkerAnalytics(accountId: accountId, scriptName: projectName, days: days)
        if let items, !items.isEmpty {
            return items
        }
        
        // Fallback: Query pagesFunctionsInvocationsAdaptiveGroups with proper dimensions
        let pastDate: Date
        if days == 1 {
            pastDate = Calendar.current.date(byAdding: .hour, value: -24, to: Date()) ?? Date()
        } else {
            pastDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        }
        let startDateString = DateFormatters.iso8601.string(from: pastDate)
        let endDateString = DateFormatters.iso8601.string(from: Date())
        
        let dimension = (days == 1) ? "datetimeHour" : "date"
        let orderBy = (days == 1) ? "datetimeHour_ASC" : "date_ASC"
        
        let query = """
        query {
          viewer {
            accounts(filter: { accountTag: "\(accountId)" }) {
              pagesFunctionsInvocationsAdaptiveGroups(
                limit: 1000,
                filter: {
                  datetime_geq: "\(startDateString)",
                  datetime_leq: "\(endDateString)"
                },
                orderBy: [\(orderBy)]
              ) {
                dimensions {
                  \(dimension)
                  scriptName
                }
                sum {
                  requests
                  errors
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
            let list = decoded.data?.viewer.accounts?.first?.pagesFunctionsInvocationsAdaptiveGroups ?? []
            return list.filter { $0.dimensions.scriptName == projectName || $0.dimensions.scriptName == nil }
        } catch {
            return items ?? []
        }
    }
}
