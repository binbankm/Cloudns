import Foundation
import SwiftUI
import Combine

@MainActor
final class AlertingViewModel: BaseLoadableViewModel {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var availableTypes: [AlertingAvailableType] = []
    @Published var policies: [AlertingPolicy] = []
    @Published var webhooks: [AlertingWebhookDestination] = []
    
    init(accountId: String) {
        self.accountId = accountId
        super.init()
    }
    
    func fetchData() async {
        await executeLoadingTask {
            async let fetchTypes: [AlertingAvailableType] = {
                (try? await self.apiClient.listAvailableAlertTypes(accountId: self.accountId)) ?? []
            }()
            async let fetchPol: [AlertingPolicy] = {
                (try? await self.apiClient.listAlertingPolicies(accountId: self.accountId)) ?? []
            }()
            async let fetchHooks: [AlertingWebhookDestination] = {
                (try? await self.apiClient.listAlertingWebhooks(accountId: self.accountId)) ?? []
            }()
            
            let (types, pols, hooks) = await (fetchTypes, fetchPol, fetchHooks)
            self.availableTypes = types
            self.policies = pols
            self.webhooks = hooks
        }
    }
    
    func deletePolicy(id: String) async {
        do {
            try await apiClient.deleteAlertingPolicy(accountId: accountId, policyId: id)
            ToastManager.shared.showSuccess("Policy Deleted", message: "")
            await fetchData()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}
