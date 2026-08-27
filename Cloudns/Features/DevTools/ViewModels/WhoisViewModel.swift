import Foundation
import SwiftUI
import Combine

@MainActor
final class WhoisViewModel: BaseLoadableViewModel {
    // MARK: - Published Properties
    @Published var domainInput = ""
    @Published var info: WhoisInfo?
    
    // MARK: - Public Methods
    func performLookup() async {
        let trimmed = domainInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        info = nil
        
        await executeLoadingTask {
            self.info = try await RDAPService.shared.lookup(domain: trimmed)
        }
    }
}
