import Foundation

// MARK: - Dynamic Redirect Rules Models

public struct RedirectRuleItem: Codable, Identifiable, Equatable {
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
    
    private struct ActionParams: Codable {
        let fromValue: FromValue?
        enum CodingKeys: String, CodingKey {
            case fromValue = "from_value"
        }
    }
    
    private struct FromValue: Codable {
        let statusCode: Int?
        let targetUrl: TargetUrlObj?
        let preserveQueryString: Bool?
        
        enum CodingKeys: String, CodingKey {
            case statusCode = "status_code"
            case targetUrl = "target_url"
            case preserveQueryString = "preserve_query_string"
        }
    }
    
    private struct TargetUrlObj: Codable {
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
    
    public static let placeholders: [RedirectRuleItem] = [
        RedirectRuleItem(id: "redir_1", description: "Redirect HTTP to HTTPS", expression: "http.request.uri.path eq \"/old-docs\"", targetUrl: "https://docs.example.com/v2", statusCode: 301),
        RedirectRuleItem(id: "redir_2", description: "Forward Blog traffic", expression: "http.host eq \"blog.example.com\"", targetUrl: "https://example.com/blog", statusCode: 302)
    ]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.expression = try container.decodeIfPresent(String.self, forKey: .expression)
        self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)
        
        if let params = try container.decodeIfPresent(ActionParams.self, forKey: .actionParameters),
           let fromVal = params.fromValue {
            self.statusCode = fromVal.statusCode
            self.targetUrl = fromVal.targetUrl?.value ?? fromVal.targetUrl?.expression
            self.preserveQueryString = fromVal.preserveQueryString
        } else {
            self.targetUrl = try container.decodeIfPresent(String.self, forKey: .targetUrl)
            self.statusCode = try container.decodeIfPresent(Int.self, forKey: .statusCode)
            self.preserveQueryString = nil
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
