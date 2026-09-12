import Combine
import Foundation

@MainActor
final class NetworkSettingsViewModel: BaseLoadableViewModel {
    @Published var ipv6: Bool = false
    @Published var websockets: Bool = false
    @Published var http2: Bool = false
    @Published var http3: Bool = false
    @Published var ipGeolocation: Bool = false
    @Published var originMaxHttpVersion: String = "2"

    private let networkService: NetworkSettingsServiceProtocol

    init(networkService: NetworkSettingsServiceProtocol = NetworkSettingsService.shared) {
        self.networkService = networkService
        super.init()
    }

    func fetchSettings(zoneId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let res = try await networkService.getNetworkSettings(zoneId: zoneId)
            ipv6 = res.ipv6
            websockets = res.websockets
            http2 = res.http2
            http3 = res.http3
            ipGeolocation = res.ipGeolocation
            originMaxHttpVersion = res.originMaxHttpVersion
            hasFetchedData = true
        } catch {
            errorMessage = "Failed to load network settings: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func updateIPv6(zoneId: String, isOn: Bool) async {
        let previous = ipv6
        ipv6 = isOn
        do {
            try await networkService.updateIPv6(zoneId: zoneId, isOn: isOn)
        } catch {
            ipv6 = previous
            errorMessage = error.localizedDescription
        }
    }

    func updateWebsockets(zoneId: String, isOn: Bool) async {
        let previous = websockets
        websockets = isOn
        do {
            try await networkService.updateWebsockets(zoneId: zoneId, isOn: isOn)
        } catch {
            websockets = previous
            errorMessage = error.localizedDescription
        }
    }

    func updateHTTP2(zoneId: String, isOn: Bool) async {
        let previous = http2
        http2 = isOn
        do {
            try await networkService.updateHTTP2(zoneId: zoneId, isOn: isOn)
        } catch {
            http2 = previous
            errorMessage = error.localizedDescription
        }
    }

    func updateHTTP3(zoneId: String, isOn: Bool) async {
        let previous = http3
        http3 = isOn
        do {
            try await networkService.updateHTTP3(zoneId: zoneId, isOn: isOn)
        } catch {
            http3 = previous
            errorMessage = error.localizedDescription
        }
    }

    func updateIPGeolocation(zoneId: String, isOn: Bool) async {
        let previous = ipGeolocation
        ipGeolocation = isOn
        do {
            try await networkService.updateIPGeolocation(zoneId: zoneId, isOn: isOn)
        } catch {
            ipGeolocation = previous
            errorMessage = error.localizedDescription
        }
    }

    func updateOriginMaxHTTPVersion(zoneId: String, version: String) async {
        let previous = originMaxHttpVersion
        originMaxHttpVersion = version
        do {
            try await networkService.updateOriginMaxHTTPVersion(zoneId: zoneId, version: version)
        } catch {
            originMaxHttpVersion = previous
            errorMessage = error.localizedDescription
        }
    }
}
