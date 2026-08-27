import Foundation
import SwiftUI
import Combine

@MainActor
final class NetworkSettingsViewModel: BaseLoadableViewModel {
    @Published var ipv6: Bool = false
    @Published var websockets: Bool = false
    @Published var http2: Bool = false
    @Published var http3: Bool = false
    @Published var ipGeolocation: Bool = false
    @Published var originMaxHttpVersion: String = "2"
    
    private let networkService: SpeedAndNetworkServiceProtocol
    
    init(networkService: SpeedAndNetworkServiceProtocol = SpeedAndNetworkService.shared) {
        self.networkService = networkService
        super.init()
    }
    
    func fetchSettings(zoneId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let res = try await networkService.getNetworkSettings(zoneId: zoneId)
            self.ipv6 = res.ipv6
            self.websockets = res.websockets
            self.http2 = res.http2
            self.http3 = res.http3
            self.ipGeolocation = res.ipGeolocation
            self.originMaxHttpVersion = res.originMaxHttpVersion
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to load network settings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateIPv6(zoneId: String, isOn: Bool) async {
        let previous = self.ipv6
        self.ipv6 = isOn
        HapticManager.impact(.medium)
        do {
            try await networkService.updateIPv6(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess("IPv6", message: isOn ? "Enabled" : "Disabled")
        } catch {
            self.ipv6 = previous
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func updateWebsockets(zoneId: String, isOn: Bool) async {
        let previous = self.websockets
        self.websockets = isOn
        HapticManager.impact(.medium)
        do {
            try await networkService.updateWebsockets(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess("WebSockets", message: isOn ? "Enabled" : "Disabled")
        } catch {
            self.websockets = previous
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func updateHTTP2(zoneId: String, isOn: Bool) async {
        let previous = self.http2
        self.http2 = isOn
        HapticManager.impact(.medium)
        do {
            try await networkService.updateHTTP2(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess("HTTP/2", message: isOn ? "Enabled" : "Disabled")
        } catch {
            self.http2 = previous
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func updateHTTP3(zoneId: String, isOn: Bool) async {
        let previous = self.http3
        self.http3 = isOn
        HapticManager.impact(.medium)
        do {
            try await networkService.updateHTTP3(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess("HTTP/3 (QUIC)", message: isOn ? "Enabled" : "Disabled")
        } catch {
            self.http3 = previous
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func updateIPGeolocation(zoneId: String, isOn: Bool) async {
        let previous = self.ipGeolocation
        self.ipGeolocation = isOn
        HapticManager.impact(.medium)
        do {
            try await networkService.updateIPGeolocation(zoneId: zoneId, isOn: isOn)
            ToastManager.shared.showSuccess("IP Geolocation", message: isOn ? "Enabled" : "Disabled")
        } catch {
            self.ipGeolocation = previous
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func updateOriginMaxHTTPVersion(zoneId: String, version: String) async {
        let previous = self.originMaxHttpVersion
        self.originMaxHttpVersion = version
        HapticManager.impact(.medium)
        do {
            try await networkService.updateOriginMaxHTTPVersion(zoneId: zoneId, version: version)
            ToastManager.shared.showSuccess("Origin Max HTTP", message: version == "2" ? "HTTP/2" : "HTTP/1.1")
        } catch {
            self.originMaxHttpVersion = previous
            self.errorMessage = error.localizedDescription
            ToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
}
