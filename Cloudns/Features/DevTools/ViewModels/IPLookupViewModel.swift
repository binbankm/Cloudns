import Foundation
import SwiftUI
import Combine

@MainActor
final class IPLookupViewModel: BaseLoadableViewModel {
    private let devToolsService: DevToolsServiceProtocol
    
    @Published var ipInput: String = ""
    @Published var lookupResult: IPLookupResult?
    
    init(devToolsService: DevToolsServiceProtocol = DevToolsService.shared) {
        self.devToolsService = devToolsService
        super.init()
    }
    
    func queryIP() async {
        let target = ipInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return }
        lookupResult = nil
        
        await executeLoadingTask {
            self.lookupResult = try await self.devToolsService.lookupIP(target: target)
        }
    }
}
