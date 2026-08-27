import Foundation
import SwiftUI
import Combine

@MainActor
final class IPLookupViewModel: BaseLoadableViewModel {
    // MARK: - Private Properties
    private let devToolsService: DevToolsServiceProtocol
    
    // MARK: - Published Properties
    @Published var ipInput: String = ""
    @Published var lookupResult: IPLookupResult?
    
    // MARK: - Lifecycle / Init
    init(devToolsService: DevToolsServiceProtocol = DevToolsService.shared) {
        self.devToolsService = devToolsService
        super.init()
    }
    
    // MARK: - Public Methods
    func queryIP() async {
        let target = ipInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return }
        lookupResult = nil
        
        await executeLoadingTask {
            self.lookupResult = try await self.devToolsService.lookupIP(target: target)
        }
    }
}
