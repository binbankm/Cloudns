import Foundation
import SwiftUI
import Combine

@MainActor
class AuditLogsViewModel: BaseLoadableViewModel {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var logs: [AuditLog] = []
    @Published var searchText: String = ""
    
    init(accountId: String) {
        self.accountId = accountId
        super.init()
    }
    
    var filteredLogs: [AuditLog] {
        if searchText.isEmpty { return logs }
        return logs.filter {
            ($0.action?.type?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.actor?.email?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.resource?.type?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    func fetchLogs() async {
        await executeLoadingTask {
            var targetAccountId = self.accountId
            if targetAccountId.isEmpty {
                let accounts = try? await self.apiClient.getAccounts()
                let activeEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
                targetAccountId = accounts?.first(where: { $0.name == activeEmail || $0.id == activeEmail })?.id ?? accounts?.first?.id ?? ""
            }
            
            guard !targetAccountId.isEmpty else {
                self.logs = []
                return
            }
            
            self.logs = try await self.apiClient.getAuditLogs(accountId: targetAccountId)
        }
    }
}
