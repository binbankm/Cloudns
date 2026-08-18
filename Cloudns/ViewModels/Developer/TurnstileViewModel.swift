import Foundation
import SwiftUI
import Combine

@MainActor
class TurnstileViewModel: BaseLoadableViewModel {
    let accountId: String
    private let turnstileService: TurnstileServiceProtocol
    
    @Published var widgets: [TurnstileWidget] = []
    @Published var searchText: String = ""
    
    init(accountId: String, turnstileService: TurnstileServiceProtocol = TurnstileService.shared) {
        self.accountId = accountId
        self.turnstileService = turnstileService
        super.init()
    }
    
    var filteredWidgets: [TurnstileWidget] {
        if searchText.isEmpty { return widgets }
        return widgets.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchWidgets() async {
        await executeLoadingTask {
            self.widgets = try await self.turnstileService.getTurnstileWidgets(accountId: self.accountId)
        }
    }
    
    func createWidget(name: String, domains: [String], mode: String) async throws -> TurnstileWidget {
        let input = TurnstileCreateInput(name: name, domains: domains, mode: mode)
        let created = try await turnstileService.createTurnstileWidget(accountId: accountId, input: input)
        self.widgets.insert(created, at: 0)
        return created
    }
    
    func updateWidget(sitekey: String, name: String, domains: [String], mode: String) async throws {
        let input = TurnstileUpdateInput(name: name, domains: domains, mode: mode)
        let updated = try await turnstileService.updateTurnstileWidget(accountId: accountId, sitekey: sitekey, input: input)
        if let idx = widgets.firstIndex(where: { $0.sitekey == sitekey }) {
            widgets[idx] = updated
        }
    }
    
    func deleteWidget(sitekey: String) async throws {
        try await turnstileService.deleteTurnstileWidget(accountId: accountId, sitekey: sitekey)
        widgets.removeAll(where: { $0.sitekey == sitekey })
    }
    
    func rotateSecret(sitekey: String, invalidateImmediately: Bool) async throws -> String {
        let newSecret = try await turnstileService.rotateTurnstileSecret(accountId: accountId, sitekey: sitekey, invalidateImmediately: invalidateImmediately)
        await fetchWidgets()
        return newSecret
    }
}
