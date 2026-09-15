import Foundation

// MARK: - Dynamic Redirect Rules Models

public struct RedirectRuleItem: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let description: String?
    public let expression: String?
    public let targetUrl: String?
    public let statusCode: Int?
    public let preserveQueryString: Bool?
    public let enabled: Bool?

    enum CodingKeys: String, CodingKey {
        case id, description, expression, enabled
        case actionParameters = "action_parameters"
        case targetUrl = "target_url"
        case statusCode = "status_code"
    }

    private struct ActionParams: Codable, Sendable {
        let fromValue: FromValue?
        enum CodingKeys: String, CodingKey {
            case fromValue = "from_value"
        }
    }

    private struct FromValue: Codable, Sendable {
        let statusCode: Int?
        let targetUrl: TargetUrlObj?
        let preserveQueryString: Bool?

        enum CodingKeys: String, CodingKey {
            case statusCode = "status_code"
            case targetUrl = "target_url"
            case preserveQueryString = "preserve_query_string"
        }
    }

    private struct TargetUrlObj: Codable, Sendable {
        let value: String?
        let expression: String?
    }

    public init(id: String, description: String?, expression: String?, targetUrl: String?, statusCode: Int?, preserveQueryString: Bool? = nil, enabled: Bool? = true) {
        self.id = id
        self.description = description
        self.expression = expression
        self.targetUrl = targetUrl
        self.statusCode = statusCode
        self.preserveQueryString = preserveQueryString
        self.enabled = enabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        expression = try container.decodeIfPresent(String.self, forKey: .expression)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)

        if let params = try container.decodeIfPresent(ActionParams.self, forKey: .actionParameters),
           let fromVal = params.fromValue {
            statusCode = fromVal.statusCode
            targetUrl = fromVal.targetUrl?.value ?? fromVal.targetUrl?.expression
            preserveQueryString = fromVal.preserveQueryString
        } else {
            targetUrl = try container.decodeIfPresent(String.self, forKey: .targetUrl)
            statusCode = try container.decodeIfPresent(Int.self, forKey: .statusCode)
            preserveQueryString = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(expression, forKey: .expression)
        try container.encodeIfPresent(enabled, forKey: .enabled)
        try container.encodeIfPresent(targetUrl, forKey: .targetUrl)
        try container.encodeIfPresent(statusCode, forKey: .statusCode)
    }
}
