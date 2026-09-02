import Foundation

/// Protocol defining Cloudflare web performance and speed optimization service
protocol SpeedSettingsServiceProtocol: Sendable {
    func getSpeedSettings(zoneId: String) async throws -> (brotli: Bool, rocketLoader: Bool, earlyHints: Bool, speedBrain: Bool, fonts: Bool, tieredCache: Bool, polish: String)
    func updateBrotli(zoneId: String, isOn: Bool) async throws
    func updateRocketLoader(zoneId: String, isOn: Bool) async throws
    func updateEarlyHints(zoneId: String, isOn: Bool) async throws
    func updateSpeedBrain(zoneId: String, isOn: Bool) async throws
    func updateFonts(zoneId: String, isOn: Bool) async throws
    func updateTieredCache(zoneId: String, isOn: Bool) async throws
    func updatePolish(zoneId: String, value: String) async throws
}

/// Concrete domain service for Cloudflare web optimization
final class SpeedSettingsService: SpeedSettingsServiceProtocol {
    static let shared = SpeedSettingsService()
    
    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared
    
    private init() {}
    
    func getSpeedSettings(zoneId: String) async throws -> (brotli: Bool, rocketLoader: Bool, earlyHints: Bool, speedBrain: Bool, fonts: Bool, tieredCache: Bool, polish: String) {
        async let br = try? getSetting(zoneId: zoneId, settingName: "brotli")
        async let rl = try? getSetting(zoneId: zoneId, settingName: "rocket_loader")
        async let eh = try? getSetting(zoneId: zoneId, settingName: "early_hints")
        async let sb = try? getSetting(zoneId: zoneId, settingName: "speed_brain")
        async let fn = try? getSetting(zoneId: zoneId, settingName: "fonts")
        async let pl = try? getSetting(zoneId: zoneId, settingName: "polish")
        let (brotli, rocket, hints, speedBrain, fonts, polish) = await (br, rl, eh, sb, fn, pl)
        
        let tieredCacheOn = await getTieredCacheStatus(zoneId: zoneId)
        
        return (
            brotli: brotli?.value.boolValue ?? false,
            rocketLoader: rocket?.value.boolValue ?? false,
            earlyHints: hints?.value.boolValue ?? false,
            speedBrain: speedBrain?.value.boolValue ?? false,
            fonts: fonts?.value.boolValue ?? false,
            tieredCache: tieredCacheOn,
            polish: polish?.value.stringValue ?? "off"
        )
    }
    
    func updateBrotli(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "brotli", value: isOn ? "on" : "off")
    }
    
    func updateRocketLoader(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "rocket_loader", value: isOn ? "on" : "off")
    }
    
    func updateEarlyHints(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "early_hints", value: isOn ? "on" : "off")
    }
    
    func updateSpeedBrain(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "speed_brain", value: isOn ? "on" : "off")
    }
    
    func updateFonts(zoneId: String, isOn: Bool) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "fonts", value: isOn ? "on" : "off")
    }
    
    func updateTieredCache(zoneId: String, isOn: Bool) async throws {
        let payload = ["value": isOn ? "on" : "off"]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/argo/tiered_caching", method: "PATCH", body: data)
        let (_, _): (ZoneSetting?, ResultInfo?) = try await client.performRequest(request)
    }
    
    func updatePolish(zoneId: String, value: String) async throws {
        _ = try await updateSetting(zoneId: zoneId, settingName: "polish", value: value)
    }
    
    private func getTieredCacheStatus(zoneId: String) async -> Bool {
        do {
            let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/argo/tiered_caching")
            struct TieredRes: Codable {
                let value: String?
            }
            let (res, _): (TieredRes?, ResultInfo?) = try await client.performRequest(request)
            return (res?.value ?? "off").lowercased() == "on"
        } catch {
            return false
        }
    }
    
    private func getSetting(zoneId: String, settingName: String) async throws -> ZoneSetting? {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/settings/\(settingName)")
        let (setting, _): (ZoneSetting?, ResultInfo?) = try await client.performRequest(request)
        return setting
    }
    
    private func updateSetting(zoneId: String, settingName: String, value: Any) async throws -> ZoneSetting {
        let payload = ["value": value]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/settings/\(settingName)", method: "PATCH", body: data)
        let (setting, _): (ZoneSetting?, ResultInfo?) = try await client.performRequest(request)
        guard let s = setting else {
            throw APIError.cloudflareError("Failed to update \(settingName).")
        }
        return s
    }
}
