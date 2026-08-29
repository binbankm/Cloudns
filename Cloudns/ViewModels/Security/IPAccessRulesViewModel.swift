import Foundation
import SwiftUI
import Combine

@MainActor
final class IPAccessRulesViewModel: BaseLoadableViewModel {
    @Published var rules: [IPAccessRule] = []
    @Published var isCreating: Bool = false
    
    private let securityService: SecuritySettingsServiceProtocol
    
    init(securityService: SecuritySettingsServiceProtocol = SecuritySettingsService.shared) {
        self.securityService = securityService
        super.init()
    }
    
    func fetchRules(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let (fetched, _) = try await securityService.getIPAccessRules(zoneId: zoneId, page: 1, perPage: 50)
            self.rules = fetched
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to fetch access rules: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createRule(zoneId: String, mode: String, target: String, value: String, notes: String) async -> Bool {
        isCreating = true
        errorMessage = nil
        
        do {
            let newRule = try await securityService.createIPAccessRule(
                zoneId: zoneId,
                mode: mode,
                target: target,
                value: value,
                notes: notes
            )
            
            // Insert at the top
            self.rules.insert(newRule, at: 0)
            HapticManager.notification(.success)
            isCreating = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            HapticManager.notification(.error)
            isCreating = false
            return false
        }
    }
    
    func deleteRule(zoneId: String, ruleId: String) async {
        do {
            try await securityService.deleteIPAccessRule(zoneId: zoneId, ruleId: ruleId)
            self.rules.removeAll { $0.id == ruleId }
            HapticManager.notification(.success)
        } catch {
            self.errorMessage = error.localizedDescription
            HapticManager.notification(.error)
        }
    }
}
