import Combine
import Foundation

@MainActor
final class IPAccessRulesViewModel: BaseLoadableViewModel {
    @Published var rules: [IPAccessRule] = []
    @Published var isCreating: Bool = false

    private let accessRulesService: IPAccessRulesServiceProtocol

    init(accessRulesService: IPAccessRulesServiceProtocol = IPAccessRulesService.shared) {
        self.accessRulesService = accessRulesService
        super.init()
    }

    func fetchRules(zoneId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let (fetched, _) = try await accessRulesService.getIPAccessRules(zoneId: zoneId, page: 1, perPage: 50)
            rules = fetched
            hasFetchedData = true
        } catch {
            errorMessage = "Failed to fetch access rules: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func createRule(zoneId: String, mode: String, target: String, value: String, notes: String?) async -> Bool {
        isCreating = true
        defer { isCreating = false }

        do {
            let newRule = try await accessRulesService.createIPAccessRule(zoneId: zoneId, mode: mode, target: target, value: value, notes: notes)
            rules.insert(newRule, at: 0)
            return true
        } catch {
            errorMessage = "Failed to create rule: \(error.localizedDescription)"
            return false
        }
    }

    func deleteRule(zoneId: String, ruleId: String) async {
        do {
            try await accessRulesService.deleteIPAccessRule(zoneId: zoneId, ruleId: ruleId)
            rules.removeAll { $0.id == ruleId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
