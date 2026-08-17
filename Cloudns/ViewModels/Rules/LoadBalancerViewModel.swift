import Foundation
import SwiftUI
import Combine

@MainActor
class LoadBalancerViewModel: BaseLoadableViewModel {
    let zoneId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var loadBalancers: [LoadBalancer] = []
    @Published var pools: [LBPool] = []
    @Published var monitors: [LBMonitor] = []
    
    init(zoneId: String) {
        self.zoneId = zoneId
    }
    
    func fetchData() async {
        await executeLoadingTask {
            let zone = try await self.apiClient.getZoneDetails(zoneId: self.zoneId)
            let accountId = zone.account?.id ?? ""
            
            async let fetchLBs = self.apiClient.getLoadBalancers(zoneId: self.zoneId)
            async let fetchPools = self.apiClient.getLBPools(accountId: accountId)
            async let fetchMonitors = self.apiClient.getLBMonitors(accountId: accountId)
            
            let (newLBs, newPools, newMonitors) = try await (fetchLBs, fetchPools, fetchMonitors)
            self.loadBalancers = newLBs
            self.pools = newPools
            self.monitors = newMonitors
        }
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
    
    func createPool(payload: LBPoolUpdate) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let zone = try await apiClient.getZoneDetails(zoneId: zoneId)
            let accountId = zone.account?.id ?? ""
            _ = try await apiClient.createLBPool(accountId: accountId, pool: payload)
            ToastManager.shared.showSuccess("Pool Created", message: payload.name)
            await fetchData()
            return true
        } catch {
            errorMessage = error.localizedDescription
            ToastManager.shared.showError("Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deletePool(poolId: String) async {
        do {
            let zone = try await apiClient.getZoneDetails(zoneId: zoneId)
            let accountId = zone.account?.id ?? ""
            try await apiClient.deleteLBPool(accountId: accountId, poolId: poolId)
            ToastManager.shared.showSuccess("Pool Deleted", message: "")
            await fetchData()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
    
    func createMonitor(payload: LBMonitorUpdate) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let zone = try await apiClient.getZoneDetails(zoneId: zoneId)
            let accountId = zone.account?.id ?? ""
            _ = try await apiClient.createLBMonitor(accountId: accountId, monitor: payload)
            ToastManager.shared.showSuccess("Monitor Created", message: payload.description ?? payload.type)
            await fetchData()
            return true
        } catch {
            errorMessage = error.localizedDescription
            ToastManager.shared.showError("Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deleteMonitor(monitorId: String) async {
        do {
            let zone = try await apiClient.getZoneDetails(zoneId: zoneId)
            let accountId = zone.account?.id ?? ""
            try await apiClient.deleteLBMonitor(accountId: accountId, monitorId: monitorId)
            ToastManager.shared.showSuccess("Monitor Deleted", message: "")
            await fetchData()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}
