import Foundation
import SwiftUI
import Combine

@MainActor
class LoadBalancerViewModel: ObservableObject {
    let zoneId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var loadBalancers: [LoadBalancer] = []
    @Published var pools: [LBPool] = []
    @Published var monitors: [LBMonitor] = []
    
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(zoneId: String) {
        self.zoneId = zoneId
    }
    
    func fetchData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let zone = try await apiClient.getZoneDetails(zoneId: zoneId)
            let accountId = zone.account?.id ?? ""
            
            async let fetchLBs = apiClient.getLoadBalancers(zoneId: zoneId)
            async let fetchPools = apiClient.getLBPools(accountId: accountId)
            async let fetchMonitors = apiClient.getLBMonitors(accountId: accountId)
            
            let (newLBs, newPools, newMonitors) = try await (fetchLBs, fetchPools, fetchMonitors)
            self.loadBalancers = newLBs
            self.pools = newPools
            self.monitors = newMonitors
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to load Load Balancer data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createLoadBalancer(payload: LoadBalancerUpdate) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            _ = try await apiClient.createLoadBalancer(zoneId: zoneId, payload: payload)
            await fetchData()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func deleteLoadBalancer(id: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await apiClient.deleteLoadBalancer(zoneId: zoneId, lbId: id)
            await fetchData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
