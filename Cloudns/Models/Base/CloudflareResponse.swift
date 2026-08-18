import Foundation

public struct CloudflareResponse<T: Codable & Sendable>: Codable, Sendable {
    public let success: Bool
    public let errors: [CloudflareError]?
    public let result: T?
    public let resultInfo: ResultInfo?
    
    enum CodingKeys: String, CodingKey {
        case success, errors, result
        case resultInfo = "result_info"
    }
}

public struct ResultInfo: Codable, Equatable, Sendable {
    public let page: Int
    public let perPage: Int
    public let totalPages: Int
    public let count: Int
    public let totalCount: Int
    public let cursor: String?
    public let cursors: ResultCursors?
    
    public struct ResultCursors: Codable, Equatable, Sendable {
        public let before: String?
        public let after: String?
        
        public init(before: String? = nil, after: String? = nil) {
            self.before = before
            self.after = after
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "per_page"
        case totalPages = "total_pages"
        case count
        case totalCount = "total_count"
        case cursor
        case cursors
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 1
        self.perPage = try container.decodeIfPresent(Int.self, forKey: .perPage) ?? 50
        self.totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages) ?? 1
        self.count = try container.decodeIfPresent(Int.self, forKey: .count) ?? 0
        self.totalCount = try container.decodeIfPresent(Int.self, forKey: .totalCount) ?? 0
        self.cursor = try container.decodeIfPresent(String.self, forKey: .cursor)
        self.cursors = try container.decodeIfPresent(ResultCursors.self, forKey: .cursors)
    }
    
    public init(page: Int = 1, perPage: Int = 50, totalPages: Int = 1, count: Int = 0, totalCount: Int = 0, cursor: String? = nil, cursors: ResultCursors? = nil) {
        self.page = page
        self.perPage = perPage
        self.totalPages = totalPages
        self.count = count
        self.totalCount = totalCount
        self.cursor = cursor
        self.cursors = cursors
    }
}

public struct CloudflareError: Codable, Equatable, Sendable {
    public let code: Int
    public let message: String
}
