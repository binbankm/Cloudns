import Foundation

// MARK: - Turnstile Models

public struct TurnstileWidget: Codable, Identifiable, Equatable, Sendable {
    public var id: String { sitekey }
    public let sitekey: String
    public let name: String
    public let mode: String?
    public let domains: [String]?
    public let secret: String?
    public let createdOn: String?
    public let modifiedOn: String?
    
    enum CodingKeys: String, CodingKey {
        case sitekey, name, mode, domains, secret
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
    }
    
    public init(
        sitekey: String,
        name: String,
        mode: String? = "managed",
        domains: [String]? = ["example.com"],
        secret: String? = nil,
        createdOn: String? = "2024-01-01T00:00:00Z",
        modifiedOn: String? = "2024-01-01T00:00:00Z"
    ) {
        self.sitekey = sitekey
        self.name = name
        self.mode = mode
        self.domains = domains
        self.secret = secret
        self.createdOn = createdOn
        self.modifiedOn = modifiedOn
    }
    
    public static let placeholders: [TurnstileWidget] = (0..<4).map { idx in
        TurnstileWidget(sitekey: "0x4AAAAAAAXyZ\(idx + 1)", name: "Login Captcha Widget \(idx + 1)")
    }
}

public struct TurnstileCreateInput: Codable, Sendable {
    public let name: String
    public let domains: [String]
    public let mode: String
    public let region: String?
    
    public init(name: String, domains: [String], mode: String = "managed", region: String? = "world") {
        self.name = name
        self.domains = domains
        self.mode = mode
        self.region = region
    }
}

public struct TurnstileUpdateInput: Codable, Sendable {
    public let name: String
    public let domains: [String]
    public let mode: String
    
    public init(name: String, domains: [String], mode: String) {
        self.name = name
        self.domains = domains
        self.mode = mode
    }
}
