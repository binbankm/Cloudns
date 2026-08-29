import Foundation
import SwiftUI
import Combine

@MainActor
final class WhoisViewModel: BaseLoadableViewModel {
    @Published var domainInput = ""
    @Published var info: WhoisInfo?
    
    private let whoisService: WhoisServiceProtocol
    
    init(whoisService: WhoisServiceProtocol = WhoisService.shared) {
        self.whoisService = whoisService
        super.init()
    }
    
    func performLookup() async {
        let trimmed = domainInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        info = nil
        
        await executeLoadingTask {
            self.info = try await self.whoisService.lookup(domain: trimmed)
            self.hasFetchedData = true
        }
    }
}
