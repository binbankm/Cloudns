import Foundation
import SwiftUI
import Combine

@MainActor
class WorkerSecretsViewModel: BaseLoadableViewModel {
    let accountId: String
    let scriptName: String
    private let workerService: WorkerServiceProtocol
    
    @Published var selectedTab: String = "variables" // "variables" | "secrets"
    @Published var plainVariables: [WorkerBinding] = []
    @Published var secrets: [WorkerSecret] = []
    @Published var allBindings: [WorkerBinding] = []
    @Published var searchText: String = ""
    
    init(accountId: String, scriptName: String, workerService: WorkerServiceProtocol = WorkerService.shared) {
        self.accountId = accountId
        self.scriptName = scriptName
        self.workerService = workerService
        super.init()
    }
    
    var filteredVariables: [WorkerBinding] {
        if searchText.isEmpty { return plainVariables }
        return plainVariables.filter { $0.name.localizedCaseInsensitiveContains(searchText) || ($0.text?.localizedCaseInsensitiveContains(searchText) ?? false) }
    }
    
    var filteredSecrets: [WorkerSecret] {
        if searchText.isEmpty { return secrets }
        return secrets.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchSecrets() async {
        await executeLoadingTask {
            async let fetchedSecrets = self.workerService.getWorkerSecrets(accountId: self.accountId, scriptName: self.scriptName)
            async let fetchedBindings = self.workerService.getWorkerBindings(accountId: self.accountId, scriptName: self.scriptName)
            
            let (secList, bindList) = try await (fetchedSecrets, fetchedBindings)
            self.secrets = secList
            self.allBindings = bindList
            self.plainVariables = bindList.filter { $0.type == "plain_text" }
        }
    }
    
    func savePlainVariable(name: String, value: String) async throws {
        var updated = allBindings.filter { $0.name != name }
        updated.append(WorkerBinding(name: name, type: "plain_text", namespaceId: nil, bucketName: nil, databaseId: nil, text: value))
        try await workerService.patchWorkerBindings(accountId: accountId, scriptName: scriptName, bindings: updated)
        await fetchSecrets()
    }
    
    func deletePlainVariable(name: String) async throws {
        let updated = allBindings.filter { $0.name != name }
        try await workerService.patchWorkerBindings(accountId: accountId, scriptName: scriptName, bindings: updated)
        await fetchSecrets()
    }
    
    func saveSecret(name: String, value: String) async throws {
        try await workerService.putWorkerSecret(accountId: accountId, scriptName: scriptName, name: name, text: value)
        await fetchSecrets()
    }
    
    func deleteSecret(name: String) async throws {
        try await workerService.deleteWorkerSecret(accountId: accountId, scriptName: scriptName, name: name)
        await fetchSecrets()
    }
}
