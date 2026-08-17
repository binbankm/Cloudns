import Foundation
import SwiftUI
import Combine

@MainActor
class IPAccessRulesViewModel: BaseLoadableViewModel {
    @Published var rules: [IPAccessRule] = []
    @Published var isCreating: Bool = false
    
    let apiClient = CloudflareAPIClient.shared
    
    func fetchRules(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            self.rules = try await apiClient.fetchIPAccessRules(zoneId: zoneId)
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
            let newRule = try await apiClient.createIPAccessRule(
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
            self.errorMessage = "Failed to create rule: \(error.localizedDescription)"
            
            HapticManager.notification(.error)
            
            isCreating = false
            return false
        }
    }
    
    func deleteRule(zoneId: String, ruleId: String) async {
        do {
            try await apiClient.deleteIPAccessRule(zoneId: zoneId, ruleId: ruleId)
            
            // Remove from local list
            self.rules.removeAll { $0.id == ruleId }
            
            HapticManager.notification(.success)
        } catch {
            self.errorMessage = "Failed to delete rule: \(error.localizedDescription)"
            
            HapticManager.notification(.error)
        }
    }
}
