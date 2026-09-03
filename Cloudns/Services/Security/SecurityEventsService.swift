import Foundation

/// Protocol defining Cloudflare security events GraphQL telemetry service
protocol SecurityEventsServiceProtocol: Sendable {
    func fetchSecurityEvents(zoneId: String, limit: Int) async throws -> [SecurityEvent]
}

/// Concrete domain service for Cloudflare security events
final class SecurityEventsService: SecurityEventsServiceProtocol {
    static let shared = SecurityEventsService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    func fetchSecurityEvents(zoneId: String, limit: Int = 30) async throws -> [SecurityEvent] {
        let date = Calendar.current.date(byAdding: .hour, value: -23, to: Date()) ?? Date()
        let dateString = DateFormatters.iso8601.string(from: date)
        
        let query = """
        query {
            viewer {
                zones(filter: { zoneTag: "\(zoneId)" }) {
                    firewallEventsAdaptive(filter: { datetime_gt: "\(dateString)" }, limit: \(limit), orderBy: [datetime_DESC]) {
                        action
                        clientIP
                        clientCountryName
                        clientAsn
                        datetime
                        source
                        edgeResponseStatus
                        clientRequestHTTPHost
                        ruleId
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
            let decoded = try JSONDecoder().decode(GraphQLResponse<SecurityGraphQLData>.self, from: rawData)
            if let errors = decoded.errors, !errors.isEmpty, decoded.data == nil {
                throw APIError.cloudflareError(errors.first?.message ?? "Failed to fetch security events")
            }
            return decoded.data?.viewer.zones.first?.firewallEventsAdaptive ?? []
        } catch let apiError as APIError {
            throw apiError
        } catch {
            return []
        }
    }
}
