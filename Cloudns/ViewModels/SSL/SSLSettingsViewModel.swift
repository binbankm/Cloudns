import Foundation
import SwiftUI
import Combine

@MainActor
class SSLSettingsViewModel: BaseLoadableViewModel {
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
    
    private let certService: CertificateServiceProtocol
    
    init(certService: CertificateServiceProtocol = CertificateService.shared) {
        self.certService = certService
        super.init()
    }
    
    func fetchSettings(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let res = try await certService.getSSLSettings(zoneId: zoneId)
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
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to fetch SSL settings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateSSLMode(zoneId: String, mode: String) async {
        HapticManager.impact(.medium)
        do {
            try await certService.updateSSLMode(zoneId: zoneId, mode: mode)
            self.sslMode = mode
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateAlwaysUseHTTPS(zoneId: String, isOn: Bool) async {
        HapticManager.impact(.medium)
        do {
            try await certService.updateAlwaysUseHTTPS(zoneId: zoneId, isOn: isOn)
            self.alwaysUseHTTPS = isOn
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateAutomaticHTTPSRewrites(zoneId: String, isOn: Bool) async {
        HapticManager.impact(.medium)
        do {
            try await certService.updateAutomaticHTTPSRewrites(zoneId: zoneId, isOn: isOn)
            self.automaticHTTPSRewrites = isOn
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateMinTLSVersion(zoneId: String, version: String) async {
        HapticManager.impact(.medium)
        do {
            try await certService.updateMinTLSVersion(zoneId: zoneId, version: version)
            self.minTLSVersion = version
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateTLS13(zoneId: String, isOn: Bool) async {
        HapticManager.impact(.medium)
        do {
            try await certService.updateTLS13(zoneId: zoneId, isOn: isOn)
            self.tls13 = isOn
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateOpportunisticEncryption(zoneId: String, isOn: Bool) async {
        HapticManager.impact(.medium)
        do {
            try await certService.updateOpportunisticEncryption(zoneId: zoneId, isOn: isOn)
            self.opportunisticEncryption = isOn
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateOpportunisticOnion(zoneId: String, isOn: Bool) async {
        HapticManager.impact(.medium)
        do {
            try await certService.updateOpportunisticOnion(zoneId: zoneId, isOn: isOn)
            self.opportunisticOnion = isOn
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func updateHSTS(zoneId: String, enabled: Bool, maxAge: Int, subdomains: Bool, nosniff: Bool) async {
        HapticManager.impact(.medium)
        do {
            try await certService.updateHSTS(zoneId: zoneId, enabled: enabled, maxAge: maxAge, subdomains: subdomains, nosniff: nosniff)
            self.hstsEnabled = enabled
            self.hstsMaxAge = maxAge
            self.hstsIncludeSubdomains = subdomains
            self.hstsNoSniff = nosniff
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
