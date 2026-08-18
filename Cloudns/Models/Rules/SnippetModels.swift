import Foundation

// MARK: - Snippets Models

public struct SnippetItem: Codable, Identifiable, Equatable, Sendable {
    public var id: String { snippet_name }
    public let snippet_name: String
    public let modifiedOn: String?
    public let createdOn: String?
    
    enum CodingKeys: String, CodingKey {
        case snippet_name
        case modifiedOn = "modified_on"
        case createdOn = "created_on"
    }
    
    public init(snippet_name: String, modifiedOn: String? = nil, createdOn: String? = nil) {
        self.snippet_name = snippet_name
        self.modifiedOn = modifiedOn
        self.createdOn = createdOn
    }
    
    public static let placeholders: [SnippetItem] = [
        SnippetItem(snippet_name: "add_security_headers", modifiedOn: "2024-01-01T00:00:00Z"),
        SnippetItem(snippet_name: "normalize_uri_path", modifiedOn: "2024-01-01T00:00:00Z")
    ]
}
