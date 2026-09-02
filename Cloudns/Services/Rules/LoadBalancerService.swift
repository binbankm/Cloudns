import Foundation

/// Protocol defining Cloudflare Load Balancing domain service
protocol LoadBalancerServiceProtocol: Sendable {
    func getLoadBalancers(zoneId: String) async throws -> [LoadBalancer]
    func getLBPools(accountId: String) async throws -> [LBPool]
    func getLBMonitors(accountId: String) async throws -> [LBMonitor]
    func createLoadBalancer(zoneId: String, lb: LoadBalancerUpdate) async throws -> LoadBalancer
    func deleteLoadBalancer(zoneId: String, lbId: String) async throws
    func createLBPool(accountId: String, pool: LBPoolUpdate) async throws -> LBPool
    func deleteLBPool(accountId: String, poolId: String) async throws
    func createLBMonitor(accountId: String, monitor: LBMonitorUpdate) async throws -> LBMonitor
    func deleteLBMonitor(accountId: String, monitorId: String) async throws
}

/// Concrete domain service for Cloudflare Load Balancing
final class LoadBalancerService: LoadBalancerServiceProtocol {
    static let shared = LoadBalancerService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    func getLoadBalancers(zoneId: String) async throws -> [LoadBalancer] {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/load_balancers")
        let (lbs, _): ([LoadBalancer]?, ResultInfo?) = try await client.performRequest(request)
        return lbs ?? []
    }
    
    func getLBPools(accountId: String) async throws -> [LBPool] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/load_balancers/pools")
        let (pools, _): ([LBPool]?, ResultInfo?) = try await client.performRequest(request)
        return pools ?? []
    }
    
    func getLBMonitors(accountId: String) async throws -> [LBMonitor] {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/load_balancers/monitors")
        let (monitors, _): ([LBMonitor]?, ResultInfo?) = try await client.performRequest(request)
        return monitors ?? []
    }
    
    func createLoadBalancer(zoneId: String, lb: LoadBalancerUpdate) async throws -> LoadBalancer {
        let encoder = JSONEncoder()
        let data = try encoder.encode(lb)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/load_balancers", method: "POST", body: data)
        let (created, _): (LoadBalancer?, ResultInfo?) = try await client.performRequest(request)
        guard let item = created else { throw APIError.cloudflareError("Failed to create load balancer.") }
        return item
    }
    
    func deleteLoadBalancer(zoneId: String, lbId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/load_balancers/\(lbId)", method: "DELETE")
        struct DeleteResult: Codable { let id: String? }
        let (_, _): (DeleteResult?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func createLBPool(accountId: String, pool: LBPoolUpdate) async throws -> LBPool {
        let encoder = JSONEncoder()
        let data = try encoder.encode(pool)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/load_balancers/pools", method: "POST", body: data)
        let (created, _): (LBPool?, ResultInfo?) = try await client.performRequest(request)
        guard let p = created else { throw APIError.cloudflareError("Failed to create LB pool") }
        return p
    }
    
    func deleteLBPool(accountId: String, poolId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/load_balancers/pools/\(poolId)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func createLBMonitor(accountId: String, monitor: LBMonitorUpdate) async throws -> LBMonitor {
        let encoder = JSONEncoder()
        let data = try encoder.encode(monitor)
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/load_balancers/monitors", method: "POST", body: data)
        let (created, _): (LBMonitor?, ResultInfo?) = try await client.performRequest(request)
        guard let m = created else { throw APIError.cloudflareError("Failed to create LB monitor") }
        return m
    }
    
    func deleteLBMonitor(accountId: String, monitorId: String) async throws {
        let request = try factory.createAuthenticatedRequest(path: "accounts/\(accountId)/load_balancers/monitors/\(monitorId)", method: "DELETE")
        struct Res: Codable { let id: String? }
        let (_, _): (Res?, ResultInfo?) = try await client.performRequest(request)
    }
}
