import Foundation
import SwiftUI
import Combine

@MainActor
final class SnippetsViewModel: ObservableObject {
    @Published var snippets: [SnippetItem] = []
    @Published var rules: [WAFRule] = []
    @Published var rulesetId: String?
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    private let apiClient = CloudflareAPIClient.shared
    
    func fetchSnippets(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchList = apiClient.getSnippets(zoneId: zoneId)
            async let fetchRules = apiClient.getSnippetRuleset(zoneId: zoneId)
            let (snips, (rId, rRules)) = try await (fetchList, fetchRules)
            self.snippets = snips
            self.rulesetId = rId
            self.rules = rRules
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func deleteSnippet(zoneId: String, snippetName: String) async -> Bool {
        do {
            try await apiClient.deleteSnippet(zoneId: zoneId, snippetName: snippetName)
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
            try await apiClient.putSnippet(zoneId: zoneId, name: name.trimmingCharacters(in: .whitespaces), code: code)
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
            try await apiClient.bindSnippetRule(zoneId: zoneId, snippetName: snippetName, expression: expression, description: description)
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
            try await apiClient.deleteSnippetRule(zoneId: zoneId, rulesetId: rulesetId, ruleId: ruleId)
            ToastManager.shared.showSuccess("Rule Removed", message: "")
            await fetchSnippets(zoneId: zoneId)
            return true
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func loadSnippetContent(zoneId: String, name: String) async -> String? {
        return try? await apiClient.getSnippetContent(zoneId: zoneId, name: name)
    }
}
