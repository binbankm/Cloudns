import Foundation
import SwiftUI
import Combine

@MainActor
class IPLookupViewModel: BaseLoadableViewModel {
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var ipInput: String = ""
    @Published var lookupResult: IPLookupResult?
    
    func queryIP() async {
        let target = ipInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return }
        lookupResult = nil
        
        await executeLoadingTask {
            self.lookupResult = try await self.apiClient.lookupIP(target: target)
        }
    }
}
