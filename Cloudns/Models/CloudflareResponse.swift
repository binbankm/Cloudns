import Foundation

public struct CloudflareResponse<T: Codable>: Codable {
    public let success: Bool
    public let errors: [CloudflareError]?
    public let result: T?
    public let resultInfo: ResultInfo?
    
    enum CodingKeys: String, CodingKey {
        case success, errors, result
        case resultInfo = "result_info"
    }
}

public struct ResultInfo: Codable {
    public let page: Int
    public let perPage: Int
    public let totalPages: Int
    public let count: Int
    public let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "per_page"
        case totalPages = "total_pages"
        case count
        case totalCount = "total_count"
    }
}

public struct CloudflareError: Codable {
    public let code: Int
    public let message: String
}
