import Foundation
import SwiftUI
import Combine

@MainActor
final class AlertingViewModel: BaseLoadableViewModel {
    // MARK: - Private Properties
    let accountId: String
    private let alertingService: AlertingServiceProtocol
    
    // MARK: - Published Properties
    @Published var availableTypes: [AlertingAvailableType] = []
    @Published var policies: [AlertingPolicy] = []
    @Published var webhooks: [AlertingWebhookDestination] = []
    
    // MARK: - Lifecycle / Init
    init(accountId: String, alertingService: AlertingServiceProtocol = AlertingService.shared) {
        self.accountId = accountId
        self.alertingService = alertingService
        super.init()
    }
    
    // MARK: - Public Methods
    func fetchData() async {
        await executeLoadingTask {
            async let fetchTypes = (try? self.alertingService.listAvailableAlertTypes(accountId: self.accountId)) ?? []
            async let fetchPol = (try? self.alertingService.listAlertingPolicies(accountId: self.accountId)) ?? []
            async let fetchHooks = (try? self.alertingService.listAlertingWebhooks(accountId: self.accountId)) ?? []
            
            let (types, pols, hooks) = await (fetchTypes, fetchPol, fetchHooks)
            self.availableTypes = types
            self.policies = pols
            self.webhooks = hooks
        }
    }
    
    func deletePolicy(id: String) async {
        do {
            try await alertingService.deleteAlertingPolicy(accountId: accountId, policyId: id)
            CloudnsToastManager.shared.showSuccess("Policy Deleted")
            await fetchData()
        } catch {
            CloudnsToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}
