import Foundation
import SwiftUI
import Combine

@MainActor
final class AccessAppsViewModel: BaseLoadableViewModel {
    let accountId: String
    private let accessService: AccessServiceProtocol
    private let zoneService: ZoneServiceProtocol
    
    @Published var apps: [AccessApp] = []
    @Published var searchText: String = ""
    
    init(
        accountId: String,
        accessService: AccessServiceProtocol = AccessService.shared,
        zoneService: ZoneServiceProtocol = ZoneService.shared
    ) {
        self.accountId = accountId
        self.accessService = accessService
        self.zoneService = zoneService
        super.init()
    }
    
    var filteredApps: [AccessApp] {
        if searchText.isEmpty { return apps }
        return apps.filter { $0.name.localizedStandardContains(searchText) || $0.domain.localizedStandardContains(searchText) }
    }
    
    private func resolveTargetAccountId() async -> String {
        if !accountId.isEmpty { return accountId }
        let accounts = try? await zoneService.getAccounts()
        let activeEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
        return accounts?.first(where: { $0.name == activeEmail || $0.id == activeEmail })?.id ?? accounts?.first?.id ?? ""
    }
    
    func fetchApps() async {
        await executeLoadingTask {
            let targetId = await self.resolveTargetAccountId()
            guard !targetId.isEmpty else {
                self.apps = []
                return
            }
            self.apps = try await self.accessService.listAccessApps(accountId: targetId)
        }
    }
    
    func createApp(name: String, domain: String, type: String = "self_hosted", sessionDuration: String = "24h") async throws {
        let targetId = await resolveTargetAccountId()
        guard !targetId.isEmpty else { throw APIError.cloudflareError("Active account ID not found") }
        let newApp = try await accessService.createAccessApp(
            accountId: targetId,
            name: name,
            domain: domain,
            type: type,
            sessionDuration: sessionDuration
        )
        withAnimation {
            self.apps.insert(newApp, at: 0)
        }
        await fetchApps()
    }
    
    func deleteApp(id: String) async {
        do {
            let targetId = await resolveTargetAccountId()
            guard !targetId.isEmpty else { return }
            withAnimation {
                self.apps.removeAll { $0.id == id }
            }
            try await accessService.deleteAccessApp(accountId: targetId, appId: id)
            await fetchApps()
        } catch {
        }
    }
}
