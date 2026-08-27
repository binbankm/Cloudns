import Foundation
import SwiftUI
import Combine

@MainActor
class CloudflareStatusViewModel: BaseLoadableViewModel {
    @Published var summary: CFStatusSummary?
    
    private let devToolsService: DevToolsServiceProtocol
    
    init(devToolsService: DevToolsServiceProtocol = DevToolsService.shared) {
        self.devToolsService = devToolsService
        super.init()
    }
    
    func fetchStatus() async {
        await executeLoadingTask {
            let res = try await self.devToolsService.fetchCloudflareStatus()
            self.summary = res
            let snap = CFStatusWidgetSnapshot(
                indicator: res.status?.indicator ?? "none",
                description: res.status?.description ?? "All Systems Operational",
                activeIncidentsCount: res.incidents?.count ?? 0,
                latestIncidentTitle: res.incidents?.first?.name,
                lastUpdated: Date()
            )
            WidgetDataStore.shared.saveStatusSnapshot(snap)
        }
    }
}
