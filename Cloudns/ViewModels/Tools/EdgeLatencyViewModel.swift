import Foundation
import SwiftUI
import Combine

@MainActor
final class EdgeLatencyViewModel: BaseLoadableViewModel {
    @Published var latencyHostInput = ""
    @Published var latencyResult: EdgeLatencyResult?
    @Published var isLatencyLoading = false
    @Published var latencyRounds = 6
    @Published var latencyError: String?
    
    private let latencyService: EdgeLatencyServiceProtocol
    
    init(latencyService: EdgeLatencyServiceProtocol = EdgeLatencyService.shared) {
        self.latencyService = latencyService
        super.init()
    }
    
    func performEdgeLatencyTest() async {
        let clean = latencyHostInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        isLatencyLoading = true
        latencyError = nil
        latencyResult = nil
        
        do {
            let res = try await latencyService.performEdgeLatencyTest(host: clean, rounds: latencyRounds)
            self.latencyResult = res
            self.hasFetchedData = true
            HapticManager.success()
        } catch {
            self.latencyError = error.localizedDescription
            HapticManager.error()
        }
        isLatencyLoading = false
    }
    
    func testLatency() async {
        await performEdgeLatencyTest()
    }
}
