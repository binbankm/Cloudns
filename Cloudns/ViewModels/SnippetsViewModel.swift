import Foundation
import SwiftUI
import Combine

@MainActor
final class SnippetsViewModel: ObservableObject {
    @Published var snippets: [SnippetItem] = []
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    private let apiClient = CloudflareAPIClient.shared
    
    func fetchSnippets(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            self.snippets = try await apiClient.getSnippets(zoneId: zoneId)
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
            ToastManager.shared.showSuccess("Snippet", message: "Snippet saved successfully")
            await fetchSnippets(zoneId: zoneId)
            return true
        } catch {
            ToastManager.shared.showError("Save Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func loadSnippetContent(zoneId: String, name: String) async -> String? {
        return try? await apiClient.getSnippetContent(zoneId: zoneId, name: name)
    }
}
