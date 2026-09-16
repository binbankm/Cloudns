import Combine
import Foundation

// MARK: - ZoneDetailViewModel (MVVM Business Controller)

@MainActor
final class ZoneDetailViewModel: ObservableObject {
    @Published var zone: Zone
    @Published var isLoading = false
    @Published var isCheckingActivation = false
    @Published var isUnderAttack = false
    @Published var isDevelopmentMode = false
    @Published var isPurgingCache = false
    @Published var isZoneHoldEnabled = false
    @Published var isPaused = false

    // Quick summary states for Section 3 badges
    @Published var dnsRecordCount: Int?
    @Published var sslMode: String?
    @Published var securityLevel: String?

    // Subview control sheets
    @Published var showPurgeConfirmation = false
    @Published var showDeleteConfirmation = false

    private let zoneService: ZoneServiceProtocol
    private let securityService: SecuritySettingsServiceProtocol
    private let cachingService: CachingServiceProtocol
    private let dnsService: DNSServiceProtocol
    private let sslService: SSLSettingsServiceProtocol

    init(
        zone: Zone,
        zoneService: ZoneServiceProtocol = ZoneService.shared,
        securityService: SecuritySettingsServiceProtocol = SecuritySettingsService.shared,
        cachingService: CachingServiceProtocol = CachingService.shared,
        dnsService: DNSServiceProtocol = DNSService.shared,
        sslService: SSLSettingsServiceProtocol = SSLSettingsService.shared
    ) {
        self.zone = zone
        self.isPaused = zone.paused
        self.zoneService = zoneService
        self.securityService = securityService
        self.cachingService = cachingService
        self.dnsService = dnsService
        self.sslService = sslService
    }

    // MARK: - Load Initial Zone Settings & States

    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }

        // Parallel fetch latest zone status & quick indicators
        async let zoneTask: ()? = refreshZoneDetails()
        async let secTask: ()? = fetchSecuritySettings()
        async let cacheTask: ()? = fetchCachingSettings()
        async let dnsTask: ()? = fetchDNSCount()
        async let sslTask: ()? = fetchSSLSettings()
        async let holdTask: ()? = fetchZoneHold()

        _ = await (zoneTask, secTask, cacheTask, dnsTask, sslTask, holdTask)
    }

    private func refreshZoneDetails() async {
        do {
            let latest = try await zoneService.getZoneDetails(zoneId: zone.id)
            self.zone = latest
            self.isPaused = latest.paused
        } catch {
            // Silently ignore or retain current
        }
    }

    private func fetchSecuritySettings() async {
        do {
            let settings = try await securityService.getSecuritySettings(zoneId: zone.id)
            self.securityLevel = settings.securityLevel
            self.isUnderAttack = (settings.securityLevel.lowercased() == "under_attack")
        } catch {
            // Silently ignore or handle cancellation
        }
    }

    private func fetchCachingSettings() async {
        do {
            let settings = try await cachingService.getCachingSettings(zoneId: zone.id)
            self.isDevelopmentMode = settings.developmentMode
        } catch {
            // Silently ignore
        }
    }

    private func fetchDNSCount() async {
        do {
            let (records, resultInfo) = try await dnsService.getDNSRecords(
                zoneId: zone.id,
                page: 1,
                perPage: 20,
                search: nil,
                type: nil,
                order: "name",
                direction: "asc"
            )
            self.dnsRecordCount = resultInfo?.totalCount ?? records.count
        } catch {
            // Silently ignore
        }
    }

    private func fetchSSLSettings() async {
        do {
            let settings = try await sslService.getSSLSettings(zoneId: zone.id)
            self.sslMode = settings.sslMode
        } catch {
            // Silently ignore
        }
    }

    private func fetchZoneHold() async {
        do {
            let hold = try await zoneService.getZoneHold(zoneId: zone.id)
            self.isZoneHoldEnabled = hold?.hold ?? false
        } catch {
            // Silently ignore
        }
    }

    // MARK: - Quick Operations

    func toggleUnderAttack() async {
        let targetState = !isUnderAttack
        GentleHaptics.selection()
        do {
            try await securityService.setUnderAttackMode(zoneId: zone.id, enabled: targetState)
            isUnderAttack = targetState
            GentleHaptics.light()
            GentleBannerManager.shared.show(
                type: targetState ? .warning : .success,
                title: targetState ? "Under Attack Mode Enabled" : "Under Attack Mode Disabled",
                message: targetState ? "Extra verification challenges active" : "Security level restored to normal"
            )
        } catch {
            guard !(error is CancellationError) else { return }
            GentleHaptics.warning()
            GentleBannerManager.shared.show(
                type: .danger,
                title: "Failed to Update Security",
                message: error.localizedDescription
            )
        }
    }

    func toggleDevelopmentMode() async {
        let targetState = !isDevelopmentMode
        GentleHaptics.selection()
        do {
            try await cachingService.updateDevelopmentMode(zoneId: zone.id, isOn: targetState)
            isDevelopmentMode = targetState
            GentleHaptics.light()
            GentleBannerManager.shared.show(
                type: .success,
                title: targetState ? "Development Mode Enabled" : "Development Mode Disabled",
                message: targetState ? "Edge cache will be bypassed for 3 hours" : "Edge caching resumed"
            )
        } catch {
            guard !(error is CancellationError) else { return }
            GentleHaptics.warning()
            GentleBannerManager.shared.show(
                type: .danger,
                title: "Failed to Update Development Mode",
                message: error.localizedDescription
            )
        }
    }

    func purgeEverythingCache() async {
        isPurgingCache = true
        GentleHaptics.selection()
        defer { isPurgingCache = false }

        do {
            try await cachingService.purgeEverything(zoneId: zone.id)
            GentleHaptics.light()
            GentleBannerManager.shared.show(
                type: .success,
                title: "Purge Initiated",
                message: "All cached assets are being purged globally"
            )
        } catch {
            guard !(error is CancellationError) else { return }
            GentleHaptics.warning()
            GentleBannerManager.shared.show(
                type: .danger,
                title: "Purge Cache Failed",
                message: error.localizedDescription
            )
        }
    }

    // MARK: - Activation Check for Pending Domains

    func checkActivation() async {
        isCheckingActivation = true
        GentleHaptics.selection()
        defer { isCheckingActivation = false }

        do {
            let success = try await zoneService.checkActivation(zoneId: zone.id)
            GentleHaptics.light()
            if success {
                GentleBannerManager.shared.show(
                    type: .success,
                    title: "Activation Check Queued",
                    message: "Cloudflare is querying nameservers across global nodes"
                )
            } else {
                GentleBannerManager.shared.show(
                    type: .warning,
                    title: "Check Rate Limited",
                    message: "Please wait a few minutes before checking again"
                )
            }
        } catch {
            guard !(error is CancellationError) else { return }
            GentleHaptics.warning()
            GentleBannerManager.shared.show(
                type: .danger,
                title: "Activation Check Error",
                message: error.localizedDescription
            )
        }
    }

    // MARK: - Protection & Lifecycle

    var isEnterprise: Bool {
        zone.plan?.planTier == .enterprise
    }

    func toggleZoneHold() async {
        guard isEnterprise else {
            GentleHaptics.warning()
            GentleBannerManager.shared.show(
                type: .warning,
                title: "Enterprise Feature",
                message: "Zone Hold protection is exclusively available on Cloudflare Enterprise plans"
            )
            return
        }

        let targetState = !isZoneHoldEnabled
        GentleHaptics.selection()
        do {
            let res = try await zoneService.setZoneHold(zoneId: zone.id, hold: targetState, includeSubdomains: true)
            isZoneHoldEnabled = res.hold
            GentleHaptics.light()
            GentleBannerManager.shared.show(
                type: .success,
                title: targetState ? "Zone Hold Enabled" : "Zone Hold Disabled",
                message: targetState ? "Domain is locked against transfers" : "Transfer protection unlocked"
            )
        } catch {
            guard !(error is CancellationError) else { return }
            GentleHaptics.warning()
            GentleBannerManager.shared.show(
                type: .danger,
                title: "Failed to Update Zone Hold",
                message: error.localizedDescription
            )
        }
    }

    func togglePause() async {
        await setPaused(to: !isPaused)
    }

    func setPaused(to target: Bool) async {
        GentleHaptics.selection()
        do {
            try await zoneService.pauseZone(zoneId: zone.id, paused: target)
            isPaused = target
            updateLocalZone(paused: target)
            GentleHaptics.light()
            GentleBannerManager.shared.show(
                type: target ? .warning : .success,
                title: target ? "Cloudflare Paused" : "Cloudflare Resumed",
                message: target ? "Traffic routes directly to origin server" : "Cloudflare acceleration and security active"
            )
        } catch {
            guard !(error is CancellationError) else { return }

            let errString = error.localizedDescription.lowercased()
            if errString.contains("1019") || errString.contains("already paused") {
                // Self-healing: cloudflare is already paused, align local state
                isPaused = true
                updateLocalZone(paused: true)
                GentleBannerManager.shared.show(
                    type: .warning,
                    title: "Cloudflare Paused",
                    message: "Domain status synchronized with Cloudflare"
                )
                return
            } else if errString.contains("not paused") {
                // Self-healing: cloudflare is not paused, align local state
                isPaused = false
                updateLocalZone(paused: false)
                GentleBannerManager.shared.show(
                    type: .success,
                    title: "Cloudflare Resumed",
                    message: "Domain status synchronized with Cloudflare"
                )
                return
            }

            GentleHaptics.warning()
            GentleBannerManager.shared.show(
                type: .danger,
                title: "Operation Failed",
                message: error.localizedDescription
            )
        }
    }

    private func updateLocalZone(paused: Bool) {
        let updated = Zone(
            account: zone.account,
            id: zone.id,
            name: zone.name,
            status: zone.status,
            paused: paused,
            type: zone.type,
            plan: zone.plan,
            developmentMode: zone.developmentMode,
            nameServers: zone.nameServers,
            originalNameServers: zone.originalNameServers,
            originalRegistrar: zone.originalRegistrar,
            originalDnshost: zone.originalDnshost,
            modifiedOn: zone.modifiedOn,
            createdOn: zone.createdOn,
            activatedOn: zone.activatedOn
        )
        self.zone = updated
        NotificationCenter.default.post(name: .zoneUpdated, object: updated)
    }

    func deleteZone() async throws {
        GentleHaptics.warning()
        _ = try await zoneService.deleteZone(zoneId: zone.id)
        GentleBannerManager.shared.show(
            type: .success,
            title: "Domain Deleted",
            message: "Domain removed from your Cloudflare account"
        )
    }

    // MARK: - Helpers

    var nameservers: [String] {
        zone.nameServers ?? []
    }

    var nameserverString: String {
        guard let ns = zone.nameServers, !ns.isEmpty else {
            return "No Nameservers Assigned"
        }
        return ns.joined(separator: ", ")
    }

    var dnsSummary: String {
        if let count = dnsRecordCount {
            if count == 1 {
                return "1 Record"
            }
            return "\(count) Records"
        }
        return "DNS Active"
    }

    var sslSummary: String {
        guard let mode = sslMode?.lowercased() else {
            return "Full (Strict)"
        }
        switch mode {
        case "off":
            return "Off"
        case "flexible":
            return "Flexible"
        case "full":
            return "Full"
        case "strict":
            return "Full (Strict)"
        default:
            return "Full (Strict)"
        }
    }

    var securitySummary: String {
        guard let level = securityLevel?.lowercased() else {
            return "Medium Security"
        }
        switch level {
        case "essentially_off":
            return "Essentially Off"
        case "low":
            return "Low Security"
        case "medium":
            return "Medium Security"
        case "high":
            return "High Security"
        case "under_attack":
            return "Under Attack"
        default:
            return "Medium Security"
        }
    }
}
