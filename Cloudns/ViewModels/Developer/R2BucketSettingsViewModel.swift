import Foundation
import SwiftUI
import Combine

@MainActor
final class R2BucketSettingsViewModel: BaseLoadableViewModel {
    let accountId: String
    let bucketName: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var managedDomain: R2ManagedDomain?
    @Published var customDomains: [R2CustomDomain] = []
    @Published var corsRules: [R2CORSRule] = []
    @Published var isManagedDomainEnabled: Bool = false
    
    init(accountId: String, bucketName: String) {
        self.accountId = accountId
        self.bucketName = bucketName
        super.init()
    }
    
    func fetchSettings() async {
        await executeLoadingTask {
            async let fetchManaged = self.apiClient.getR2ManagedDomain(accountId: self.accountId, bucketName: self.bucketName)
            async let fetchCustom = self.apiClient.getR2CustomDomains(accountId: self.accountId, bucketName: self.bucketName)
            async let fetchCORS = self.apiClient.getR2CORS(accountId: self.accountId, bucketName: self.bucketName)
            
            let (managed, custom, cors) = try await (fetchManaged, fetchCustom, fetchCORS)
            self.managedDomain = managed
            self.isManagedDomainEnabled = managed.enabled ?? false
            self.customDomains = custom
            self.corsRules = cors
        }
    }
    
    func toggleManagedDomain(enabled: Bool) async {
        isManagedDomainEnabled = enabled
        do {
            try await apiClient.setR2ManagedDomain(accountId: accountId, bucketName: bucketName, enabled: enabled)
            HapticManager.impact(.light)
            ToastManager.shared.showSuccess("Managed Domain Updated", message: enabled ? "r2.dev access enabled" : "r2.dev access disabled")
            await fetchSettings()
        } catch {
            isManagedDomainEnabled = !enabled
            ToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func deleteCustomDomain(domain: String) async {
        do {
            try await apiClient.deleteR2CustomDomain(accountId: accountId, bucketName: bucketName, domain: domain)
            HapticManager.impact(.medium)
            ToastManager.shared.showSuccess("Domain Removed", message: domain)
            await fetchSettings()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
    
    func saveCORSRule(rule: R2CORSRule) async -> Bool {
        var updated = corsRules
        updated.append(rule)
        do {
            try await apiClient.putR2CORS(accountId: accountId, bucketName: bucketName, rules: updated)
            HapticManager.impact(.medium)
            ToastManager.shared.showSuccess("CORS Rule Added", message: "Allowed origins: \(rule.allowedOrigins.joined(separator: ", "))")
            await fetchSettings()
            return true
        } catch {
            ToastManager.shared.showError("Save Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deleteCORSRule(at index: Int) async {
        var updated = corsRules
        guard index < updated.count else { return }
        updated.remove(at: index)
        do {
            if updated.isEmpty {
                try await apiClient.deleteR2CORS(accountId: accountId, bucketName: bucketName)
            } else {
                try await apiClient.putR2CORS(accountId: accountId, bucketName: bucketName, rules: updated)
            }
            HapticManager.impact(.medium)
            ToastManager.shared.showSuccess("CORS Rule Removed", message: "")
            await fetchSettings()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}
