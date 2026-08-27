import Foundation
import SwiftUI
import Combine

@MainActor
final class LoadBalancerViewModel: BaseLoadableViewModel {
    // MARK: - Private Properties
    let zoneId: String
    private let lbService: LoadBalancerServiceProtocol
    private let zoneService: ZoneServiceProtocol
    
    // MARK: - Published Properties
    @Published var loadBalancers: [LoadBalancer] = []
    @Published var pools: [LBPool] = []
    @Published var monitors: [LBMonitor] = []
    
    private var cachedAccountId: String?
    
    // MARK: - Lifecycle / Init
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
    
    // MARK: - Private Methods
    private func resolveAccountId() async throws -> String {
        if let aid = cachedAccountId, !aid.isEmpty {
            return aid
        }
        let zone = try await self.zoneService.getZoneDetails(zoneId: self.zoneId)
        let aid = zone.account?.id ?? ""
        self.cachedAccountId = aid
        return aid
    }
    
    // MARK: - Public Methods
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
            CloudnsToastManager.shared.showSuccess("Load Balancer Created", message: payload.name)
            await fetchData()
            return true
        } catch {
            errorMessage = error.localizedDescription
            CloudnsToastManager.shared.showError("Creation Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deleteLoadBalancer(id: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await lbService.deleteLoadBalancer(zoneId: zoneId, lbId: id)
            CloudnsToastManager.shared.showSuccess("Load Balancer Deleted")
            await fetchData()
        } catch {
            errorMessage = error.localizedDescription
            CloudnsToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
    
    func createPool(payload: LBPoolUpdate) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let accountId = try await resolveAccountId()
            _ = try await lbService.createLBPool(accountId: accountId, pool: payload)
            CloudnsToastManager.shared.showSuccess("Pool Created", message: payload.name)
            await fetchData()
            return true
        } catch {
            errorMessage = error.localizedDescription
            CloudnsToastManager.shared.showError("Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deletePool(poolId: String) async {
        do {
            let accountId = try await resolveAccountId()
            try await lbService.deleteLBPool(accountId: accountId, poolId: poolId)
            CloudnsToastManager.shared.showSuccess("Pool Deleted")
            await fetchData()
        } catch {
            CloudnsToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
    
    func createMonitor(payload: LBMonitorUpdate) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let accountId = try await resolveAccountId()
            _ = try await lbService.createLBMonitor(accountId: accountId, monitor: payload)
            CloudnsToastManager.shared.showSuccess("Monitor Created", message: payload.description ?? payload.type)
            await fetchData()
            return true
        } catch {
            errorMessage = error.localizedDescription
            CloudnsToastManager.shared.showError("Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deleteMonitor(monitorId: String) async {
        do {
            let accountId = try await resolveAccountId()
            try await lbService.deleteLBMonitor(accountId: accountId, monitorId: monitorId)
            CloudnsToastManager.shared.showSuccess("Monitor Deleted")
            await fetchData()
        } catch {
            CloudnsToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}
