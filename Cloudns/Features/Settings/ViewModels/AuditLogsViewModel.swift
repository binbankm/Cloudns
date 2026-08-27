import Foundation
import SwiftUI
import Combine

@MainActor
final class AuditLogsViewModel: BaseLoadableViewModel {
    let accountId: String
    private let zoneService: ZoneServiceProtocol
    
    @Published var logs: [AuditLog] = []
    @Published var searchText: String = ""
    
    init(accountId: String, zoneService: ZoneServiceProtocol = ZoneService.shared) {
        self.accountId = accountId
        self.zoneService = zoneService
        super.init()
    }
    
    var filteredLogs: [AuditLog] {
        if searchText.isEmpty { return logs }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return logs.filter {
            $0.displayActionKey.localizedStandardContains(query) ||
            $0.friendlyResourceTypeKey.localizedStandardContains(query) ||
            ($0.action?.type?.localizedStandardContains(query) ?? false) ||
            ($0.action?.info?.localizedStandardContains(query) ?? false) ||
            ($0.actor?.email?.localizedStandardContains(query) ?? false) ||
            ($0.actor?.ip?.localizedStandardContains(query) ?? false) ||
            ($0.resource?.type?.localizedStandardContains(query) ?? false) ||
            ($0.resource?.id?.localizedStandardContains(query) ?? false) ||
            ($0.zone?.name?.localizedStandardContains(query) ?? false) ||
            ($0.metadata?["zone_name"]?.stringValue?.localizedStandardContains(query) ?? false) ||
            ($0.metadata?["script_name"]?.stringValue?.localizedStandardContains(query) ?? false)
        }
    }
    
    func fetchLogs() async {
        await executeLoadingTask {
            var targetAccountId = self.accountId
            if targetAccountId.isEmpty {
                let accounts = try? await self.zoneService.getAccounts()
                let activeEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
                targetAccountId = accounts?.first(where: { $0.name == activeEmail || $0.id == activeEmail })?.id ?? accounts?.first?.id ?? ""
            }
            
            guard !targetAccountId.isEmpty else {
                self.logs = []
                return
            }
            
            self.logs = try await self.zoneService.getAuditLogs(accountId: targetAccountId)
        }
    }
}
