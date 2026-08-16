import Foundation
import SwiftUI
import Combine

@MainActor
final class RedirectRulesViewModel: ObservableObject {
    @Published var rules: [RedirectRuleItem] = []
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    private let apiClient = CloudflareAPIClient.shared
    
    func fetchRules(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            self.rules = try await apiClient.getRedirectRules(zoneId: zoneId)
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func deleteRule(zoneId: String, ruleId: String, description: String?) async -> Bool {
        do {
            try await apiClient.deleteRedirectRule(zoneId: zoneId, ruleId: ruleId)
            ToastManager.shared.showSuccess("Rule Deleted", message: description ?? "Redirect Rule")
            await fetchRules(zoneId: zoneId)
            return true
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func createRule(
        zoneId: String,
        description: String,
        expression: String,
        targetUrl: String,
        statusCode: Int,
        preserveQueryString: Bool = false
    ) async -> Bool {
        do {
            try await apiClient.createRedirectRule(
                zoneId: zoneId,
                description: description.trimmingCharacters(in: .whitespaces),
                expression: expression.trimmingCharacters(in: .whitespaces),
                targetUrl: targetUrl.trimmingCharacters(in: .whitespaces),
                statusCode: statusCode,
                preserveQueryString: preserveQueryString
            )
            ToastManager.shared.showSuccess("Redirect Rule Added", message: description)
            await fetchRules(zoneId: zoneId)
            return true
        } catch {
            ToastManager.shared.showError("Create Failed", message: error.localizedDescription)
            return false
        }
    }
}
