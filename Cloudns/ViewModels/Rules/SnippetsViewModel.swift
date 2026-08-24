import Foundation
import SwiftUI
import Combine

@MainActor
final class SnippetsViewModel: BaseLoadableViewModel {
    @Published var snippets: [SnippetItem] = []
    @Published var rules: [WAFRule] = []
    @Published var rulesetId: String?
    
    private let snippetService: SnippetServiceProtocol
    
    init(snippetService: SnippetServiceProtocol = SnippetService.shared) {
        self.snippetService = snippetService
        super.init()
    }
    
    func fetchSnippets(zoneId: String) async {
        await executeLoadingTask {
            async let fetchList = self.snippetService.getSnippets(zoneId: zoneId)
            async let fetchRules = self.snippetService.getSnippetRuleset(zoneId: zoneId)
            let (snips, (rId, rRules)) = try await (fetchList, fetchRules)
            self.snippets = snips
            self.rulesetId = rId
            self.rules = rRules
        }
    }
    
    func deleteSnippet(zoneId: String, snippetName: String) async -> Bool {
        do {
            try await snippetService.deleteSnippet(zoneId: zoneId, snippetName: snippetName)
            ToastManager.shared.showSuccess("Snippet Deleted", message: snippetName)
            await fetchSnippets(zoneId: zoneId)
            return true
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func saveSnippet(zoneId: String, name: String, code: String) async -> Bool {
        do {
            try await snippetService.putSnippet(zoneId: zoneId, name: name.trimmingCharacters(in: .whitespaces), code: code)
            ToastManager.shared.showSuccess("Snippet Saved", message: name)
            await fetchSnippets(zoneId: zoneId)
            return true
        } catch {
            ToastManager.shared.showError("Save Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func bindSnippetRule(zoneId: String, snippetName: String, expression: String, description: String?) async -> Bool {
        do {
            try await snippetService.bindSnippetRule(zoneId: zoneId, snippetName: snippetName, expression: expression, description: description)
            ToastManager.shared.showSuccess("Snippet Bound", message: "\(snippetName) -> \(expression)")
            await fetchSnippets(zoneId: zoneId)
            return true
        } catch {
            ToastManager.shared.showError("Binding Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deleteSnippetRule(zoneId: String, rulesetId: String, ruleId: String) async -> Bool {
        do {
            try await snippetService.deleteSnippetRule(zoneId: zoneId, rulesetId: rulesetId, ruleId: ruleId)
            ToastManager.shared.showSuccess("Rule Removed")
            await fetchSnippets(zoneId: zoneId)
            return true
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func loadSnippetContent(zoneId: String, name: String) async -> String? {
        return try? await snippetService.getSnippetContent(zoneId: zoneId, name: name)
    }
}
