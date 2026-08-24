import Foundation

public struct ZonePlan: Codable, Equatable, Sendable {
    public let id: String?
    public let name: String?
    public let price: Double?
    public let currency: String?
    public let frequency: String?
    public let isSubscribed: Bool?
    public let canSubscribe: Bool?
    public let legacyId: String?
    
    public init(id: String? = nil, name: String? = nil, price: Double? = nil, currency: String? = nil, frequency: String? = nil, isSubscribed: Bool? = nil, canSubscribe: Bool? = nil, legacyId: String? = nil) {
        self.id = id
        self.name = name
        self.price = price
        self.currency = currency
        self.frequency = frequency
        self.isSubscribed = isSubscribed
        self.canSubscribe = canSubscribe
        self.legacyId = legacyId
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, price, currency, frequency
        case isSubscribed = "is_subscribed"
        case canSubscribe = "can_subscribe"
        case legacyId = "legacy_id"
    }
    
    public var displayName: String {
        if let name = name, !name.isEmpty {
            let lower = name.lowercased()
            if lower.contains("free") { return "Free" }
            if lower.contains("pro") { return "Pro" }
            if lower.contains("business") { return "Business" }
            if lower.contains("enterprise") { return "Enterprise" }
            return name
        }
        if let legacy = legacyId, !legacy.isEmpty {
            return legacy.capitalized
        }
        return "Free"
    }
    
    public var planTier: PlanTier {
        let text = (name ?? legacyId ?? "").lowercased()
        if text.contains("enterprise") { return .enterprise }
        if text.contains("business") || text.contains("biz") { return .business }
        if text.contains("pro") { return .pro }
        return .free
    }
}

public struct ZoneAccount: Codable, Equatable, Sendable {
    public let id: String
    public let name: String?
    
    public init(id: String, name: String? = nil) {
        self.id = id
        self.name = name
    }
}

public struct Zone: Codable, Identifiable, Equatable, Sendable {
    public let account: ZoneAccount?
    public let id: String
    public let name: String
    public let status: String
    public let paused: Bool
    public let type: String?
    public let plan: ZonePlan?
    public let developmentMode: Int?
    public let nameServers: [String]?
    public let originalNameServers: [String]?
    public let originalRegistrar: String?
    public let originalDnshost: String?
    public let modifiedOn: String?
    public let createdOn: String?
    public let activatedOn: String?
    
    public init(
        account: ZoneAccount? = nil,
        id: String,
        name: String,
        status: String = "active",
        paused: Bool = false,
        type: String? = "full",
        plan: ZonePlan? = ZonePlan(name: "Free"),
        developmentMode: Int? = nil,
        nameServers: [String]? = nil,
        originalNameServers: [String]? = nil,
        originalRegistrar: String? = nil,
        originalDnshost: String? = nil,
        modifiedOn: String? = "2024-01-01T00:00:00Z",
        createdOn: String? = "2024-01-01T00:00:00Z",
        activatedOn: String? = nil
    ) {
        self.account = account
        self.id = id
        self.name = name
        self.status = status
        self.paused = paused
        self.type = type
        self.plan = plan
        self.developmentMode = developmentMode
        self.nameServers = nameServers
        self.originalNameServers = originalNameServers
        self.originalRegistrar = originalRegistrar
        self.originalDnshost = originalDnshost
        self.modifiedOn = modifiedOn
        self.createdOn = createdOn
        self.activatedOn = activatedOn
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, status, paused, type, plan
        case developmentMode = "development_mode"
        case nameServers = "name_servers"
        case originalNameServers = "original_name_servers"
        case originalRegistrar = "original_registrar"
        case originalDnshost = "original_dnshost"
        case modifiedOn = "modified_on"
        case createdOn = "created_on"
        case activatedOn = "activated_on"
        case account
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? "active"
        self.paused = try container.decodeIfPresent(Bool.self, forKey: .paused) ?? false
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        self.plan = try container.decodeIfPresent(ZonePlan.self, forKey: .plan)
        self.developmentMode = try container.decodeIfPresent(Int.self, forKey: .developmentMode)
        self.nameServers = try container.decodeIfPresent([String].self, forKey: .nameServers)
        self.originalNameServers = try container.decodeIfPresent([String].self, forKey: .originalNameServers)
        self.originalRegistrar = try container.decodeIfPresent(String.self, forKey: .originalRegistrar)
        self.originalDnshost = try container.decodeIfPresent(String.self, forKey: .originalDnshost)
        self.modifiedOn = try container.decodeIfPresent(String.self, forKey: .modifiedOn)
        self.createdOn = try container.decodeIfPresent(String.self, forKey: .createdOn)
        self.activatedOn = try container.decodeIfPresent(String.self, forKey: .activatedOn)
        self.account = try container.decodeIfPresent(ZoneAccount.self, forKey: .account)
    }
    
    /// HIG 骨架屏专用占位数据
    public static let placeholders: [Zone] = (0..<6).map { idx in
        Zone(
            id: "placeholder-zone-\(idx)",
            name: "placeholder-domain-\(idx + 1).com",
            status: "active",
            paused: false,
            plan: ZonePlan(name: "Pro Plan")
        )
    }
    
    public var planTier: PlanTier {
        plan?.planTier ?? .free
    }
}
