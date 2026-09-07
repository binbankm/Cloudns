import Foundation
import SwiftUI
import Combine

@MainActor
final class CloudflareStatusViewModel: BaseLoadableViewModel {
    @Published var summary: CFStatusSummary?
    
    private let statusService: CloudflareStatusServiceProtocol
    
    init(statusService: CloudflareStatusServiceProtocol = CloudflareStatusService.shared) {
        self.statusService = statusService
        super.init()
    }
    
    func fetchStatus() async {
        await executeLoadingTask {
            let res = try await self.statusService.fetchCloudflareStatus()
            self.summary = res
            self.hasFetchedData = true
            let snap = CFStatusWidgetSnapshot(
                indicator: res.status?.indicator ?? "none",
                description: res.status?.description ?? String(localized: "All Systems Operational"),
                activeIncidentsCount: res.incidents?.count ?? 0,
                latestIncidentTitle: res.incidents?.first?.name,
                lastUpdated: Date()
            )
            WidgetDataStore.shared.saveStatusSnapshot(snap)
        }
    }
}
