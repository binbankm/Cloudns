import Foundation

// MARK: - Zone Subscription & Hold Models (Codable, Sendable, Equatable)

public struct ZoneSubscription: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let state: String?
    public let price: Double?
    public let currency: String?
    public let frequency: String?
    public let ratePlan: ZoneRatePlan?
    public let componentValues: [ZoneComponentValue]?

    enum CodingKeys: String, CodingKey {
        case id, state, price, currency, frequency
        case ratePlan = "rate_plan"
        case componentValues = "component_values"
    }

    public init(
        id: String,
        state: String? = nil,
        price: Double? = nil,
        currency: String? = nil,
        frequency: String? = nil,
        ratePlan: ZoneRatePlan? = nil,
        componentValues: [ZoneComponentValue]? = nil
    ) {
        self.id = id
        self.state = state
        self.price = price
        self.currency = currency
        self.frequency = frequency
        self.ratePlan = ratePlan
        self.componentValues = componentValues
    }
}

public struct ZoneRatePlan: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let publicName: String?
    public let currency: String?
    public let scope: String?
    public let isContract: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case publicName = "public_name"
        case currency, scope
        case isContract = "is_contract"
    }

    public init(id: String, publicName: String? = nil, currency: String? = nil, scope: String? = nil, isContract: Bool? = nil) {
        self.id = id
        self.publicName = publicName
        self.currency = currency
        self.scope = scope
        self.isContract = isContract
    }
}

public struct ZoneComponentValue: Codable, Equatable, Sendable {
    public let name: String?
    public let value: Int?
    public let defaultUnits: Int?
    public let price: Double?

    enum CodingKeys: String, CodingKey {
        case name, value, price
        case defaultUnits = "default"
    }

    public init(name: String?, value: Int?, defaultUnits: Int? = nil, price: Double? = nil) {
        self.name = name
        self.value = value
        self.defaultUnits = defaultUnits
        self.price = price
    }
}

public struct ZoneHold: Codable, Equatable, Sendable {
    public let hold: Bool
    public let holdAfter: String?
    public let includeSubdomains: Bool?

    enum CodingKeys: String, CodingKey {
        case hold
        case holdAfter = "hold_after"
        case includeSubdomains = "include_subdomains"
    }

    public init(hold: Bool, holdAfter: String? = nil, includeSubdomains: Bool? = nil) {
        self.hold = hold
        self.holdAfter = holdAfter
        self.includeSubdomains = includeSubdomains
    }
}
