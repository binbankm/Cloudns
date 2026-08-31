import Foundation

// MARK: - Bulk Redirects & Operations Models

public struct RedirectList: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let kind: String
    public let count: Int?
    public let createdOn: String?
    public let modifiedOn: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, kind, count
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
    }
    
    public init(id: String, name: String, description: String? = nil, kind: String = "redirect", count: Int? = 12, createdOn: String? = nil, modifiedOn: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.kind = kind
        self.count = count
        self.createdOn = createdOn
        self.modifiedOn = modifiedOn
    }
    
}

public struct RedirectListItem: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let redirect: RedirectItemDetail
    public let createdOn: String?
    public let modifiedOn: String?
    
    enum CodingKeys: String, CodingKey {
        case id, redirect
        case createdOn = "created_on"
        case modifiedOn = "modified_on"
    }
    
    public init(id: String, redirect: RedirectItemDetail, createdOn: String? = nil, modifiedOn: String? = nil) {
        self.id = id
        self.redirect = redirect
        self.createdOn = createdOn
        self.modifiedOn = modifiedOn
    }
    
}

public struct RedirectItemDetail: Codable, Equatable, Sendable {
    public let sourceUrl: String
    public let targetUrl: String
    public let statusCode: Int?
    public let preserveQueryString: Bool?
    public let includeSubdomains: Bool?
    public let subpathMatching: Bool?
    public let preservePathSuffix: Bool?
    
    enum CodingKeys: String, CodingKey {
        case sourceUrl = "source_url"
        case targetUrl = "target_url"
        case statusCode = "status_code"
        case preserveQueryString = "preserve_query_string"
        case includeSubdomains = "include_subdomains"
        case subpathMatching = "subpath_matching"
        case preservePathSuffix = "preserve_path_suffix"
    }
    
    public init(sourceUrl: String, targetUrl: String, statusCode: Int? = 301, preserveQueryString: Bool? = nil, includeSubdomains: Bool? = nil, subpathMatching: Bool? = nil, preservePathSuffix: Bool? = nil) {
        self.sourceUrl = sourceUrl
        self.targetUrl = targetUrl
        self.statusCode = statusCode
        self.preserveQueryString = preserveQueryString
        self.includeSubdomains = includeSubdomains
        self.subpathMatching = subpathMatching
        self.preservePathSuffix = preservePathSuffix
    }
}

public struct BulkOperationRef: Codable, Sendable {
    public let operationId: String
    enum CodingKeys: String, CodingKey {
        case operationId = "operation_id"
    }
    
    public init(operationId: String) {
        self.operationId = operationId
    }
}

public struct BulkOperation: Codable, Sendable {
    public let id: String
    public let status: String
    public let error: String?
    public let completed: String?
    
    public init(id: String, status: String, error: String? = nil, completed: String? = nil) {
        self.id = id
        self.status = status
        self.error = error
        self.completed = completed
    }
}
