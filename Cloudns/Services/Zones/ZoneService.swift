import Foundation

/// Protocol defining Cloudflare Zone domain service
protocol ZoneServiceProtocol: Sendable {
    func getZones(page: Int, perPage: Int, name: String?, status: String?) async throws -> ([Zone], ResultInfo?)
    func getZoneDetails(zoneId: String) async throws -> Zone
    func createZone(name: String, accountId: String, jumpStart: Bool) async throws -> Zone
    func deleteZone(zoneId: String) async throws -> String
    func updateZoneStatus(zoneId: String, paused: Bool) async throws
    func pauseZone(zoneId: String, paused: Bool) async throws
    func checkActivation(zoneId: String) async throws -> Bool
    func getZoneSubscription(zoneId: String) async throws -> ZoneSubscription?
    func getZoneHold(zoneId: String) async throws -> ZoneHold?
    func setZoneHold(zoneId: String, hold: Bool, includeSubdomains: Bool?) async throws -> ZoneHold
    func updateVanityNameServers(zoneId: String, vanityNameServers: [String]) async throws -> Zone
    func getZoneSettings(zoneId: String) async throws -> [ZoneSetting]
    func getZoneSetting(zoneId: String, settingName: String) async throws -> ZoneSetting?
    func updateZoneSetting(zoneId: String, settingName: String, value: Any) async throws -> ZoneSetting
}

extension ZoneServiceProtocol {
    func getZones(page: Int = 1, perPage: Int = 50, name: String? = nil, status: String? = nil) async throws -> ([Zone], ResultInfo?) {
        try await getZones(page: page, perPage: perPage, name: name, status: status)
    }
}

/// Concrete domain service for Cloudflare Zone management
final class ZoneService: ZoneServiceProtocol {
    static let shared = ZoneService()

    private let client = HTTPNetworkClient.shared
    private let factory = AuthenticatedRequestFactory.shared

    private init() {}

    /// Fetches all zones under user account
    func getZones(page: Int = 1, perPage: Int = 50, name: String? = nil, status: String? = nil) async throws -> ([Zone], ResultInfo?) {
        var queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)"),
            URLQueryItem(name: "order", value: "name"),
            URLQueryItem(name: "direction", value: "asc")
        ]
        if let name, !name.isEmpty {
            queryItems.append(URLQueryItem(name: "name", value: name))
        }
        if let status, !status.isEmpty {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }

        let request = try factory.createAuthenticatedRequest(path: "zones", queryItems: queryItems)
        let (zones, resultInfo): ([Zone]?, ResultInfo?) = try await client.performRequest(request)
        return (zones ?? [], resultInfo)
    }

    /// Fetches single zone details
    func getZoneDetails(zoneId: String) async throws -> Zone {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)")
        let (zone, _): (Zone?, ResultInfo?) = try await client.performRequest(request)
        guard let zone else {
            throw APIError.cloudflareError("Zone details not found.")
        }
        return zone
    }

    /// Creates new zone
    func createZone(name: String, accountId: String, jumpStart: Bool = false) async throws -> Zone {
        let payload: [String: Any] = [
            "name": name,
            "account": ["id": accountId],
            "jump_start": jumpStart,
            "type": "full"
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones", method: "POST", body: data)
        let (zone, _): (Zone?, ResultInfo?) = try await client.performRequest(request)
        guard let zone else {
            throw APIError.cloudflareError("Failed to create Zone.")
        }
        return zone
    }

    /// Deletes zone
    func deleteZone(zoneId: String) async throws -> String {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)", method: "DELETE")
        let (res, _): (CloudflareIDResponse?, ResultInfo?) = try await client.performRequest(request)
        return res?.id ?? zoneId
    }

    /// Pauses or resumes zone
    func updateZoneStatus(zoneId: String, paused: Bool) async throws {
        let payload = ["paused": paused]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)", method: "PATCH", body: data)
        let (_, _): (Zone?, ResultInfo?) = try await client.performRequest(request)
    }

    func pauseZone(zoneId: String, paused: Bool) async throws {
        try await updateZoneStatus(zoneId: zoneId, paused: paused)
    }

    /// Initiates another check for valid DNS data / nameservers for a zone (Official PUT /zones/{id}/activation_check)
    func checkActivation(zoneId: String) async throws -> Bool {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/activation_check", method: "PUT")
        let (res, _): (CloudflareIDResponse?, ResultInfo?) = try await client.performRequest(request)
        return res?.id != nil
    }

    /// Fetches zone subscription and plan details (GET /client/v4/zones/{zone_id}/subscription)
    func getZoneSubscription(zoneId: String) async throws -> ZoneSubscription? {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/subscription")
        let (subscription, _): (ZoneSubscription?, ResultInfo?) = try await client.performRequest(request)
        return subscription
    }

    /// Fetches zone hold status (GET /client/v4/zones/{zone_id}/hold)
    func getZoneHold(zoneId: String) async throws -> ZoneHold? {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/hold")
        let (hold, _): (ZoneHold?, ResultInfo?) = try await client.performRequest(request)
        return hold
    }

    /// Enables or disables zone hold (POST /client/v4/zones/{zone_id}/hold)
    func setZoneHold(zoneId: String, hold: Bool, includeSubdomains: Bool? = nil) async throws -> ZoneHold {
        struct ZoneHoldPayload: Encodable, Sendable {
            let hold: Bool
            let includeSubdomains: Bool?

            enum CodingKeys: String, CodingKey {
                case hold
                case includeSubdomains = "include_subdomains"
            }
        }
        let payload = ZoneHoldPayload(hold: hold, includeSubdomains: includeSubdomains)
        let body = try JSONEncoder().encode(payload)
        let request = try factory.createAuthenticatedRequest(
            path: "zones/\(zoneId)/hold",
            method: "POST",
            body: body
        )
        let (res, _): (ZoneHold?, ResultInfo?) = try await client.performRequest(request)
        guard let res else {
            throw APIError.cloudflareError("Failed to update zone hold.")
        }
        return res
    }

    /// Updates vanity nameservers for a zone (PATCH /client/v4/zones/{zone_id})
    func updateVanityNameServers(zoneId: String, vanityNameServers: [String]) async throws -> Zone {
        struct VanityPayload: Encodable, Sendable {
            let vanityNameServers: [String]

            enum CodingKeys: String, CodingKey {
                case vanityNameServers = "vanity_name_servers"
            }
        }
        let payload = VanityPayload(vanityNameServers: vanityNameServers)
        let body = try JSONEncoder().encode(payload)
        let request = try factory.createAuthenticatedRequest(
            path: "zones/\(zoneId)",
            method: "PATCH",
            body: body
        )
        let (zone, _): (Zone?, ResultInfo?) = try await client.performRequest(request)
        guard let zone else {
            throw APIError.cloudflareError("Failed to update vanity nameservers.")
        }
        return zone
    }

    /// Fetches all zone settings (GET /client/v4/zones/{zone_id}/settings)
    func getZoneSettings(zoneId: String) async throws -> [ZoneSetting] {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/settings")
        let (settings, _): ([ZoneSetting]?, ResultInfo?) = try await client.performRequest(request)
        return settings ?? []
    }

    /// Fetches a specific zone setting by name (GET /client/v4/zones/{zone_id}/settings/{setting_name})
    func getZoneSetting(zoneId: String, settingName: String) async throws -> ZoneSetting? {
        let request = try factory.createAuthenticatedRequest(path: "zones/\(zoneId)/settings/\(settingName)")
        let (setting, _): (ZoneSetting?, ResultInfo?) = try await client.performRequest(request)
        return setting
    }

    /// Updates a specific zone setting by name (PATCH /client/v4/zones/{zone_id}/settings/{setting_name})
    func updateZoneSetting(zoneId: String, settingName: String, value: Any) async throws -> ZoneSetting {
        let payload = ["value": value]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let request = try factory.createAuthenticatedRequest(
            path: "zones/\(zoneId)/settings/\(settingName)",
            method: "PATCH",
            body: data
        )
        let (setting, _): (ZoneSetting?, ResultInfo?) = try await client.performRequest(request)
        guard let s = setting else {
            throw APIError.cloudflareError("Failed to update \(settingName).")
        }
        return s
    }
}
