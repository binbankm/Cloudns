import Foundation
import SwiftUI
import Combine

@MainActor
class WhoisViewModel: BaseLoadableViewModel {
    @Published var domainInput = ""
    @Published var info: WhoisInfo?
    
    func performLookup() async {
        let trimmed = domainInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        info = nil
        
        await executeLoadingTask {
            self.info = try await RDAPService.shared.lookup(domain: trimmed)
        }
    }
}
