import Combine
import Foundation
import SwiftUI

@MainActor
final class SSLSettingsViewModel: BaseLoadableViewModel {
    @Published var sslMode: String = "off"
    @Published var alwaysUseHTTPS: Bool = false
    @Published var automaticHTTPSRewrites: Bool = false
    @Published var minTLSVersion: String = "1.0"
    @Published var tls13: Bool = false
    @Published var opportunisticEncryption: Bool = false
    @Published var opportunisticOnion: Bool = false

    // HSTS
    @Published var hstsEnabled: Bool = false
    @Published var hstsMaxAge: Int = 0
    @Published var hstsIncludeSubdomains: Bool = false
    @Published var hstsNoSniff: Bool = false
    @Published var hstsPreload: Bool = false

    private let certService: CertificateServiceProtocol

    init(certService: CertificateServiceProtocol = CertificateService.shared) {
        self.certService = certService
        super.init()
    }

    func fetchSettings(zoneId: String) async {
        await executeLoadingTask {
            let res = try await self.certService.getSSLSettings(zoneId: zoneId)
            self.sslMode = res.sslMode
            self.alwaysUseHTTPS = res.alwaysUseHTTPS
            self.automaticHTTPSRewrites = res.automaticHTTPSRewrites
            self.minTLSVersion = res.minTLSVersion
            self.tls13 = res.tls13
            self.opportunisticEncryption = res.opportunisticEncryption
            self.opportunisticOnion = res.opportunisticOnion
            self.hstsEnabled = res.hsts.enabled
            self.hstsMaxAge = res.hsts.maxAge
            self.hstsIncludeSubdomains = res.hsts.subdomains
            self.hstsNoSniff = res.hsts.nosniff
            self.hstsPreload = res.hsts.preload
            self.hasFetchedData = true
        }
    }

    func updateSSLMode(zoneId: String, mode: String) async {
        let previous = sslMode
        sslMode = mode
        HapticManager.impact(.medium)
        do {
            try await certService.updateSSLMode(zoneId: zoneId, mode: mode)
            await SWRCacheStore.shared.remove(forKey: SWRCacheStore.accountScopedKey("zone_details_\(zoneId)"))
            NotificationCenter.default.post(name: .zoneUpdated, object: nil, userInfo: ["zoneId": zoneId])
        } catch {
            sslMode = previous
            errorMessage = error.localizedDescription
        }
    }

    func updateAlwaysUseHTTPS(zoneId: String, isOn: Bool) async {
        let previous = alwaysUseHTTPS
        alwaysUseHTTPS = isOn
        HapticManager.impact(.medium)
        do {
            try await certService.updateAlwaysUseHTTPS(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess(isOn ? LocalizedStringKey("Always Use H T T P S Enabled") : LocalizedStringKey("Always Use H T T P S Disabled"))
        } catch {
            alwaysUseHTTPS = previous
            errorMessage = error.localizedDescription
        }
    }

    func updateAutomaticHTTPSRewrites(zoneId: String, isOn: Bool) async {
        let previous = automaticHTTPSRewrites
        automaticHTTPSRewrites = isOn
        HapticManager.impact(.medium)
        do {
            try await certService.updateAutomaticHTTPSRewrites(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess(isOn ? LocalizedStringKey("Automatic H T T P S Rewrites Enabled") : LocalizedStringKey("Automatic H T T P S Rewrites Disabled"))
        } catch {
            automaticHTTPSRewrites = previous
            errorMessage = error.localizedDescription
        }
    }

    func updateMinTLSVersion(zoneId: String, version: String) async {
        let previous = minTLSVersion
        minTLSVersion = version
        HapticManager.impact(.medium)
        do {
            try await certService.updateMinTLSVersion(zoneId: zoneId, version: version)
        } catch {
            minTLSVersion = previous
            errorMessage = error.localizedDescription
        }
    }

    func updateTLS13(zoneId: String, isOn: Bool) async {
        let previous = tls13
        tls13 = isOn
        HapticManager.impact(.medium)
        do {
            try await certService.updateTLS13(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess(isOn ? LocalizedStringKey("T L S13 Enabled") : LocalizedStringKey("T L S13 Disabled"))
        } catch {
            tls13 = previous
            errorMessage = error.localizedDescription
        }
    }

    func updateOpportunisticEncryption(zoneId: String, isOn: Bool) async {
        let previous = opportunisticEncryption
        opportunisticEncryption = isOn
        HapticManager.impact(.medium)
        do {
            try await certService.updateOpportunisticEncryption(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess(isOn ? LocalizedStringKey("Opportunistic Encryption Enabled") : LocalizedStringKey("Opportunistic Encryption Disabled"))
        } catch {
            opportunisticEncryption = previous
            errorMessage = error.localizedDescription
        }
    }

    func updateOpportunisticOnion(zoneId: String, isOn: Bool) async {
        let previous = opportunisticOnion
        opportunisticOnion = isOn
        HapticManager.impact(.medium)
        do {
            try await certService.updateOpportunisticOnion(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess(isOn ? LocalizedStringKey("Opportunistic Onion Enabled") : LocalizedStringKey("Opportunistic Onion Disabled"))
        } catch {
            opportunisticOnion = previous
            errorMessage = error.localizedDescription
        }
    }

    func updateHSTS(zoneId: String, enabled: Bool, maxAge: Int, subdomains: Bool, nosniff: Bool, preload: Bool = false) async {
        let prevEnabled = hstsEnabled
        let prevMaxAge = hstsMaxAge
        let prevSubdomains = hstsIncludeSubdomains
        let prevNosniff = hstsNoSniff
        let prevPreload = hstsPreload

        hstsEnabled = enabled
        hstsMaxAge = maxAge
        hstsIncludeSubdomains = subdomains
        hstsNoSniff = nosniff
        hstsPreload = preload

        HapticManager.impact(.medium)
        do {
            try await certService.updateHSTS(zoneId: zoneId, enabled: enabled, maxAge: maxAge, subdomains: subdomains, nosniff: nosniff, preload: preload)
        } catch {
            hstsEnabled = prevEnabled
            hstsMaxAge = prevMaxAge
            hstsIncludeSubdomains = prevSubdomains
            hstsNoSniff = prevNosniff
            hstsPreload = prevPreload
            errorMessage = error.localizedDescription
        }
    }
}
