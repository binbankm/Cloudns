import Foundation
import SwiftUI
import Combine

@MainActor
class LoadBalancerViewModel: BaseLoadableViewModel {
    let zoneId: String
    private let lbService: LoadBalancerServiceProtocol
    private let zoneService: ZoneServiceProtocol
    
    @Published var loadBalancers: [LoadBalancer] = []
    @Published var pools: [LBPool] = []
    @Published var monitors: [LBMonitor] = []
    
    private var cachedAccountId: String?
    
    init(
        zoneId: String,
        lbService: LoadBalancerServiceProtocol = LoadBalancerService.shared,
        zoneService: ZoneServiceProtocol = ZoneService.shared
    ) {
        self.zoneId = zoneId
        self.lbService = lbService
        self.zoneService = zoneService
        super.init()
    }
    
    private func resolveAccountId() async throws -> String {
        if let aid = cachedAccountId, !aid.isEmpty {
            return aid
        }
        let zone = try await self.zoneService.getZoneDetails(zoneId: self.zoneId)
        let aid = zone.account?.id ?? ""
        self.cachedAccountId = aid
        return aid
    }
    
    func fetchData() async {
        await executeLoadingTask {
            let accountId = try await self.resolveAccountId()
            
            async let fetchLBs = self.lbService.getLoadBalancers(zoneId: self.zoneId)
            async let fetchPools = self.lbService.getLBPools(accountId: accountId)
            async let fetchMonitors = self.lbService.getLBMonitors(accountId: accountId)
            
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
            _ = try await lbService.createLoadBalancer(zoneId: zoneId, lb: payload)
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
            try await lbService.deleteLoadBalancer(zoneId: zoneId, lbId: id)
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
            let accountId = try await resolveAccountId()
            _ = try await lbService.createLBPool(accountId: accountId, pool: payload)
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
            let accountId = try await resolveAccountId()
            try await lbService.deleteLBPool(accountId: accountId, poolId: poolId)
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
            let accountId = try await resolveAccountId()
            _ = try await lbService.createLBMonitor(accountId: accountId, monitor: payload)
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
            let accountId = try await resolveAccountId()
            try await lbService.deleteLBMonitor(accountId: accountId, monitorId: monitorId)
            ToastManager.shared.showSuccess("Monitor Deleted", message: "")
            await fetchData()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}
