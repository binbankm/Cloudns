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
            self.summary = try await self.devToolsService.fetchCloudflareStatus()
        }
    }
}
