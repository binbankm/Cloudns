import Combine
import Foundation

@MainActor
final class R2BucketSettingsViewModel: BaseLoadableViewModel {
    let accountId: String
    let bucketName: String
    private let r2Service: R2ServiceProtocol

    @Published var managedDomain: R2ManagedDomain?
    @Published var customDomains: [R2CustomDomain] = []
    @Published var corsRules: [R2CORSRule] = []
    @Published var lifecycleRules: [R2LifecycleRule] = []
    @Published var eventNotifications: [R2EventNotificationConfig] = []
    @Published var isManagedDomainEnabled: Bool = false

    init(accountId: String, bucketName: String, r2Service: R2ServiceProtocol = R2Service.shared) {
        self.accountId = accountId
        self.bucketName = bucketName
        self.r2Service = r2Service
        super.init()
    }

    func fetchSettings() async {
        await executeLoadingTask {
            async let fetchManaged = self.r2Service.getR2ManagedDomain(accountId: self.accountId, bucketName: self.bucketName)
            async let fetchCustom = self.r2Service.getR2CustomDomains(accountId: self.accountId, bucketName: self.bucketName)
            async let fetchCORS = self.r2Service.getR2CORS(accountId: self.accountId, bucketName: self.bucketName)
            async let fetchLifecycle = (try? await self.r2Service.getR2Lifecycle(accountId: self.accountId, bucketName: self.bucketName)) ?? []
            async let fetchNotifs = (try? await self.r2Service.getR2EventNotifications(accountId: self.accountId, bucketName: self.bucketName)) ?? []

            let (managed, custom, cors, lifecycle, notifs) = try await (fetchManaged, fetchCustom, fetchCORS, fetchLifecycle, fetchNotifs)
            self.managedDomain = managed
            self.isManagedDomainEnabled = managed.enabled ?? false
            self.customDomains = custom
            self.corsRules = cors
            self.lifecycleRules = lifecycle
            self.eventNotifications = notifs
        }
    }

    func toggleManagedDomain(enabled: Bool) async {
        isManagedDomainEnabled = enabled
        do {
            try await r2Service.setR2ManagedDomain(accountId: accountId, bucketName: bucketName, enabled: enabled)
            await fetchSettings()
        } catch {
            isManagedDomainEnabled = !enabled
        }
    }

    func deleteCustomDomain(domain: String) async {
        do {
            try await r2Service.deleteR2CustomDomain(accountId: accountId, bucketName: bucketName, domain: domain)
            await fetchSettings()
        } catch {}
    }

    func saveCORSRule(rule: R2CORSRule) async -> Bool {
        var updated = corsRules
        updated.append(rule)
        do {
            try await r2Service.putR2CORS(accountId: accountId, bucketName: bucketName, rules: updated)
            await fetchSettings()
            return true
        } catch {
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
            await fetchSettings()
        } catch {}
    }

    func addLifecycleRule(rule: R2LifecycleRule) async -> Bool {
        var updated = lifecycleRules
        updated.append(rule)
        do {
            try await r2Service.putR2Lifecycle(accountId: accountId, bucketName: bucketName, rules: updated)
            await fetchSettings()
            return true
        } catch {
            return false
        }
    }

    func deleteLifecycleRule(ruleId: String) async {
        let updated = lifecycleRules.filter { $0.id != ruleId }
        do {
            if updated.isEmpty {
                try await r2Service.deleteR2Lifecycle(accountId: accountId, bucketName: bucketName)
            } else {
                try await r2Service.putR2Lifecycle(accountId: accountId, bucketName: bucketName, rules: updated)
            }
            await fetchSettings()
        } catch {}
    }

    func addEventNotification(queueId: String, rules: [R2EventNotificationRule]) async -> Bool {
        do {
            try await r2Service.putR2EventNotification(accountId: accountId, bucketName: bucketName, queueId: queueId, rules: rules)
            await fetchSettings()
            return true
        } catch {
            return false
        }
    }

    func deleteEventNotification(queueId: String) async {
        do {
            try await r2Service.deleteR2EventNotification(accountId: accountId, bucketName: bucketName, queueId: queueId)
            await fetchSettings()
        } catch {}
    }
}
