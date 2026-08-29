import Foundation
import SwiftUI
import Combine

@MainActor
final class EdgeLatencyViewModel: BaseLoadableViewModel {
    @Published var host: String = "www.cloudflare.com"
    @Published var rounds: Int = 4
    @Published var result: EdgeLatencyResult?
    
    private let latencyService: EdgeLatencyServiceProtocol
    
    init(latencyService: EdgeLatencyServiceProtocol = EdgeLatencyService.shared) {
        self.latencyService = latencyService
        super.init()
    }
    
    func startTest() async {
        let clean = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        await executeLoadingTask {
            let res = try await self.latencyService.performEdgeLatencyTest(host: clean, rounds: self.rounds)
            self.result = res
            self.hasFetchedData = true
        }
    }
}
