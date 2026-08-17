import Foundation

// MARK: - Alerting Models

public struct AlertingAvailableType: Codable, Identifiable, Equatable {
    public var id: String { type }
    public let type: String
    public let displayName: String?
    public let description: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case displayName = "display_name"
        case description
    }
}

public struct AlertingWebhookDestination: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String?
    public let url: String?
    public let type: String?
    
    public init(id: String, name: String? = nil, url: String? = nil, type: String? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.type = type
    }
}

public struct AlertingPolicy: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String?
    public let description: String?
    public let enabled: Bool?
    public let alertType: String?
    public let created: String?
    public let modified: String?
    
    public var isEnabled: Bool {
        enabled ?? true
    }
    
    public var displayName: String {
        name ?? alertType ?? id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, enabled
        case alertType = "alert_type"
        case created, modified
    }
    
    public init(id: String, name: String?, description: String? = nil, enabled: Bool? = true, alertType: String? = nil, created: String? = nil, modified: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.enabled = enabled
        self.alertType = alertType
        self.created = created
        self.modified = modified
    }
    
    public static let placeholders: [AlertingPolicy] = [
        AlertingPolicy(id: "pol_1", name: "High HTTP 5xx Error Rate Alert", description: "Notifies Ops team on Slack when origin errors exceed 5%", enabled: true, alertType: "http_alert_origin_error_rate"),
        AlertingPolicy(id: "pol_2", name: "DDoS Mitigation Triggered", description: "Immediate paging when volumetric DDoS is detected", enabled: true, alertType: "dos_attack_l7")
    ]
}
