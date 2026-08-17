import Foundation
import SwiftUI
import Combine

public struct AIChatMessageItem: Identifiable, Equatable {
    public let id = UUID()
    public let role: String // "user" or "assistant"
    public let content: String
    public let timestamp = Date()
    public var isError: Bool = false
    
    public init(role: String, content: String, isError: Bool = false) {
        self.role = role
        self.content = content
        self.isError = isError
    }
}

@MainActor
class WorkersAIViewModel: BaseLoadableViewModel {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var models: [AIModel] = []
    @Published var searchText: String = ""
    
    // Chat Playground
    @Published var chatMessages: [AIChatMessageItem] = []
    @Published var promptInput: String = ""
    @Published var isSendingMessage = false
    
    init(accountId: String) {
        self.accountId = accountId
        super.init()
    }
    
    var filteredModels: [AIModel] {
        if searchText.isEmpty { return models }
        return models.filter {
            $0.shortName.localizedCaseInsensitiveContains(searchText) ||
            ($0.description ?? "").localizedCaseInsensitiveContains(searchText) ||
            $0.taskName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var groupedModels: [String: [AIModel]] {
        Dictionary(grouping: filteredModels, by: { $0.taskName })
    }
    
    func fetchModels() async {
        await executeLoadingTask {
            self.models = try await self.apiClient.getWorkersAIModels(accountId: self.accountId)
        }
    }
    
    func sendMessage(model: String) async {
        let input = promptInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty, !isSendingMessage else { return }
        
        let userMsg = AIChatMessageItem(role: "user", content: input)
        chatMessages.append(userMsg)
        promptInput = ""
        isSendingMessage = true
        
        let payloadMessages = chatMessages.filter { !$0.isError }.map { ["role": $0.role, "content": $0.content] }
        
        do {
            let reply = try await apiClient.runAIChat(accountId: accountId, model: model, messages: payloadMessages)
            let assistantMsg = AIChatMessageItem(role: "assistant", content: reply)
            chatMessages.append(assistantMsg)
        } catch {
            let errorMsg = AIChatMessageItem(role: "assistant", content: "Error: \(error.localizedDescription)", isError: true)
            chatMessages.append(errorMsg)
        }
        
        isSendingMessage = false
    }
    
    func clearChat() {
        chatMessages.removeAll()
        promptInput = ""
    }
}
