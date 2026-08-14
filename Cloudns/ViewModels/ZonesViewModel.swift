import Foundation
import SwiftUI
import Combine

@MainActor
class ZonesViewModel: ObservableObject {
    @Published var zones: [Zone] = []
    @Published var isLoading: Bool = false
    @Published var hasFetchedData: Bool = false
    @Published var errorMessage: String? = nil
    @Published var canLoadMore: Bool = false
    @Published var totalCount: Int = 0
    private var currentPage: Int = 1
    
    func fetchZones(isRefresh: Bool = true) async {
        if isRefresh {
            currentPage = 1
            isLoading = true
        } else {
            if !canLoadMore { return }
        }
        
        errorMessage = nil
        
        do {
            let (fetchedZones, resultInfo) = try await CloudflareAPIClient.shared.getZones(page: currentPage)
            
            if isRefresh {
                self.zones = fetchedZones
                self.totalCount = resultInfo?.totalCount ?? fetchedZones.count
            } else {
                self.zones.append(contentsOf: fetchedZones)
            }
            
            if let info = resultInfo, info.page < info.totalPages {
                canLoadMore = true
                currentPage += 1
            } else {
                canLoadMore = false
            }
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
            self.hasFetchedData = true
            if let apiError = error as? APIError, case .unauthorized = apiError {
                // Handle unauthorized globally if needed, for example by logging out
                // UserDefaults.standard.set(false, forKey: "isLoggedIn")
            }
        }
        
        isLoading = false
    }
    
    @Published var isAddingZone: Bool = false
    @Published var addZoneError: String? = nil
    
    func addZone(name: String) async -> Zone? {
        isAddingZone = true
        addZoneError = nil
        do {
            let accounts = try await CloudflareAPIClient.shared.getAccounts()
            guard let firstAccount = accounts.first else {
                addZoneError = "No Cloudflare account found."
                isAddingZone = false
                return nil
            }
            
            let zone = try await CloudflareAPIClient.shared.createZone(name: name, accountId: firstAccount.id)
            await fetchZones(isRefresh: true)
            isAddingZone = false
            return zone
        } catch {
            addZoneError = error.localizedDescription
            isAddingZone = false
            return nil
        }
     }
    @Published var isDeleting: Bool = false
    
    func deleteZone(zoneId: String) async {
        isDeleting = true
        errorMessage = nil
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.warning)
        do {
            try await CloudflareAPIClient.shared.deleteZone(zoneId: zoneId)
            // Remove locally
            if let index = zones.firstIndex(where: { $0.id == zoneId }) {
                zones.remove(at: index)
                totalCount -= 1
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isDeleting = false
    }
}
