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
            await fetchSnippets(zoneId: zoneId)
            return true
        } catch {
            return false
        }
    }
    
    func saveSnippet(zoneId: String, name: String, code: String) async -> Bool {
        do {
            try await snippetService.putSnippet(zoneId: zoneId, name: name.trimmingCharacters(in: .whitespaces), code: code)
            await fetchSnippets(zoneId: zoneId)
            return true
        } catch {
            return false
        }
    }
    
    func bindSnippetRule(zoneId: String, snippetName: String, expression: String, description: String?) async -> Bool {
        do {
            try await snippetService.bindSnippetRule(zoneId: zoneId, snippetName: snippetName, expression: expression, description: description)
            await fetchSnippets(zoneId: zoneId)
            return true
        } catch {
            return false
        }
    }
    
    func deleteSnippetRule(zoneId: String, rulesetId: String, ruleId: String) async -> Bool {
        do {
            try await snippetService.deleteSnippetRule(zoneId: zoneId, rulesetId: rulesetId, ruleId: ruleId)
            await fetchSnippets(zoneId: zoneId)
            return true
        } catch {
            return false
        }
    }
    
    func loadSnippetContent(zoneId: String, name: String) async -> String? {
        return try? await snippetService.getSnippetContent(zoneId: zoneId, name: name)
    }
}
