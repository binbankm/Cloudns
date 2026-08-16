import Foundation
import Combine
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var accounts: [Account] = []
    @Published var selectedAccount: Account?
    
    @Published var zones: [Zone] = []
    @Published var workers: [WorkerScript] = []
    @Published var pages: [PagesProject] = []
    @Published var tunnels: [CFTunnel] = []
    
    @Published var kvCount: Int = 0
    @Published var r2Count: Int = 0
    @Published var d1Count: Int = 0
    
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    var activeZonesCount: Int {
        zones.filter { $0.status.lowercased() == "active" }.count
    }
    
    var healthyTunnelsCount: Int {
        tunnels.filter { $0.isHealthy }.count
    }
    
    var totalStorageCount: Int {
        kvCount + r2Count + d1Count
    }
    
    var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<18: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    func fetchDashboard(isRefresh: Bool = false) async {
        if !isRefresh && hasFetchedData { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Fetch accounts
            let fetchedAccounts = try await apiClient.getAccounts()
            self.accounts = fetchedAccounts
            
            let activeEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
            let currentAcc = fetchedAccounts.first(where: { $0.name == activeEmail || $0.id == activeEmail }) ?? fetchedAccounts.first
            self.selectedAccount = currentAcc
            
            // 2. Concurrently fetch all resources
            let (fetchedZones, _) = (try? await apiClient.getZones()) ?? ([], nil)
            self.zones = fetchedZones
            
            if let accountId = currentAcc?.id, !accountId.isEmpty {
                async let fetchW = (try? await apiClient.getWorkers(accountId: accountId)) ?? []
                async let fetchP = (try? await apiClient.getPagesProjects(accountId: accountId)) ?? []
                async let fetchT = (try? await apiClient.getTunnels(accountId: accountId)) ?? []
                async let fetchK = (try? await apiClient.getKVNamespaces(accountId: accountId)) ?? []
                async let fetchR = (try? await apiClient.getR2Buckets(accountId: accountId)) ?? []
                async let fetchD = (try? await apiClient.getD1Databases(accountId: accountId)) ?? []
                
                let (w, p, t, k, r, d) = await (fetchW, fetchP, fetchT, fetchK, fetchR, fetchD)
                
                self.workers = w
                self.pages = p
                self.tunnels = t
                self.kvCount = k.count
                self.r2Count = r.count
                self.d1Count = d.count
            }
            
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
