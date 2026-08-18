import Foundation
import SwiftUI
import Combine

@MainActor
class NetworkSettingsViewModel: BaseLoadableViewModel {
    @Published var ipv6: Bool = false
    @Published var websockets: Bool = false
    @Published var http2: Bool = false
    @Published var http3: Bool = false
    @Published var ipGeolocation: Bool = false
    
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
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to load network settings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateIPv6(zoneId: String, isOn: Bool) async {
        HapticManager.impact(.medium)
        do {
            try await networkService.updateIPv6(zoneId: zoneId, isOn: isOn)
            self.ipv6 = isOn
        } catch {
            self.errorMessage = "Failed to update IPv6: \(error.localizedDescription)"
        }
    }
    
    func updateWebsockets(zoneId: String, isOn: Bool) async {
        HapticManager.impact(.medium)
        do {
            try await networkService.updateWebsockets(zoneId: zoneId, isOn: isOn)
            self.websockets = isOn
        } catch {
            self.errorMessage = "Failed to update WebSockets: \(error.localizedDescription)"
        }
    }
    
    func updateHTTP2(zoneId: String, isOn: Bool) async {
        HapticManager.impact(.medium)
        do {
            try await networkService.updateHTTP2(zoneId: zoneId, isOn: isOn)
            self.http2 = isOn
        } catch {
            self.errorMessage = "Failed to update HTTP/2: \(error.localizedDescription)"
        }
    }
    
    func updateHTTP3(zoneId: String, isOn: Bool) async {
        HapticManager.impact(.medium)
        do {
            try await networkService.updateHTTP3(zoneId: zoneId, isOn: isOn)
            self.http3 = isOn
        } catch {
            self.errorMessage = "Failed to update HTTP/3: \(error.localizedDescription)"
        }
    }
    
    func updateIPGeolocation(zoneId: String, isOn: Bool) async {
        HapticManager.impact(.medium)
        do {
            try await networkService.updateIPGeolocation(zoneId: zoneId, isOn: isOn)
            self.ipGeolocation = isOn
        } catch {
            self.errorMessage = "Failed to update IP Geolocation: \(error.localizedDescription)"
        }
    }
}
