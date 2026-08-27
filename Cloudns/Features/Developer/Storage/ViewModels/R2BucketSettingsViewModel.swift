import Foundation
import SwiftUI
import Combine

@MainActor
final class R2BucketSettingsViewModel: BaseLoadableViewModel {
    // MARK: - Private Properties
    let accountId: String
    let bucketName: String
    private let r2Service: R2ServiceProtocol
    
    // MARK: - Published Properties
    @Published var managedDomain: R2ManagedDomain?
    @Published var customDomains: [R2CustomDomain] = []
    @Published var corsRules: [R2CORSRule] = []
    @Published var isManagedDomainEnabled: Bool = false
    
    // MARK: - Lifecycle / Init
    init(accountId: String, bucketName: String, r2Service: R2ServiceProtocol = R2Service.shared) {
        self.accountId = accountId
        self.bucketName = bucketName
        self.r2Service = r2Service
        super.init()
    }
    
    // MARK: - Public Methods
    func fetchSettings() async {
        await executeLoadingTask {
            async let fetchManaged = self.r2Service.getR2ManagedDomain(accountId: self.accountId, bucketName: self.bucketName)
            async let fetchCustom = self.r2Service.getR2CustomDomains(accountId: self.accountId, bucketName: self.bucketName)
            async let fetchCORS = self.r2Service.getR2CORS(accountId: self.accountId, bucketName: self.bucketName)
            
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
            try await r2Service.setR2ManagedDomain(accountId: accountId, bucketName: bucketName, enabled: enabled)
            HapticManager.impact(.light)
            CloudnsToastManager.shared.showSuccess("Managed Domain Updated", message: enabled ? "r2.dev access enabled" : "r2.dev access disabled")
            await fetchSettings()
        } catch {
            isManagedDomainEnabled = !enabled
            CloudnsToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func deleteCustomDomain(domain: String) async {
        do {
            try await r2Service.deleteR2CustomDomain(accountId: accountId, bucketName: bucketName, domain: domain)
            HapticManager.impact(.medium)
            CloudnsToastManager.shared.showSuccess("Domain Removed", message: domain)
            await fetchSettings()
        } catch {
            CloudnsToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
    
    func saveCORSRule(rule: R2CORSRule) async -> Bool {
        var updated = corsRules
        updated.append(rule)
        do {
            try await r2Service.putR2CORS(accountId: accountId, bucketName: bucketName, rules: updated)
            HapticManager.impact(.medium)
            CloudnsToastManager.shared.showSuccess("CORS Rule Added", message: rule.allowedOrigins.joined(separator: ", "))
            await fetchSettings()
            return true
        } catch {
            CloudnsToastManager.shared.showError("Save Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deleteCORSRule(at index: Int) async {
        var updated = corsRules
        guard index < updated.count else { return }
        updated.remove(at: index)
        do {
            if updated.isEmpty {
                try await r2Service.deleteR2CORS(accountId: accountId, bucketName: bucketName)
            } else {
                try await r2Service.putR2CORS(accountId: accountId, bucketName: bucketName, rules: updated)
            }
            HapticManager.impact(.medium)
            CloudnsToastManager.shared.showSuccess("CORS Rule Removed")
            await fetchSettings()
        } catch {
            CloudnsToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}
