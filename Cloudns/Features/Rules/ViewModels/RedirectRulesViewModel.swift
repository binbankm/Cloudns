import Foundation
import SwiftUI
import Combine

@MainActor
final class RedirectRulesViewModel: BaseLoadableViewModel {
    // MARK: - Published Properties
    @Published var rules: [RedirectRuleItem] = []
    
    // MARK: - Private Properties
    private let redirectService: RedirectRulesServiceProtocol
    
    // MARK: - Lifecycle / Init
    init(redirectService: RedirectRulesServiceProtocol = RedirectRulesService.shared) {
        self.redirectService = redirectService
        super.init()
    }
    
    // MARK: - Public Methods
    func fetchRules(zoneId: String) async {
        await executeLoadingTask {
            self.rules = try await self.redirectService.getRedirectRules(zoneId: zoneId)
        }
    }
    
    func deleteRule(zoneId: String, ruleId: String, description: String?) async -> Bool {
        do {
            try await redirectService.deleteRedirectRule(zoneId: zoneId, ruleId: ruleId)
            CloudnsToastManager.shared.showSuccess("Rule Deleted", message: description ?? "Redirect Rule")
            await fetchRules(zoneId: zoneId)
            return true
        } catch {
            CloudnsToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
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
            try await redirectService.createRedirectRule(
                zoneId: zoneId,
                description: description.trimmingCharacters(in: .whitespaces),
                expression: expression.trimmingCharacters(in: .whitespaces),
                targetUrl: targetUrl.trimmingCharacters(in: .whitespaces),
                statusCode: statusCode,
                preserveQueryString: preserveQueryString
            )
            CloudnsToastManager.shared.showSuccess("Redirect Rule Added", message: description)
            await fetchRules(zoneId: zoneId)
            return true
        } catch {
            CloudnsToastManager.shared.showError("Create Failed", message: error.localizedDescription)
            return false
        }
    }
}
