import Foundation

struct CloudflareResponse<T: Codable>: Codable {
    let success: Bool
    let errors: [CloudflareError]?
    let result: T?
    let resultInfo: ResultInfo?
    
    enum CodingKeys: String, CodingKey {
        case success, errors, result
        case resultInfo = "result_info"
    }
}

struct ResultInfo: Codable {
    let page: Int
    let perPage: Int
    let totalPages: Int
    let count: Int
    let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "per_page"
        case totalPages = "total_pages"
        case count
        case totalCount = "total_count"
    }
}

struct CloudflareError: Codable {
    let code: Int
    let message: String
}

struct Zone: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let status: String
    let paused: Bool
    let type: String
    let developmentMode: Int
    let nameServers: [String]
    let originalNameServers: [String]?
    let originalRegistrar: String?
    let originalDnshost: String?
    let modifiedOn: String
    let createdOn: String
    let activatedOn: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, status, paused, type
        case developmentMode = "development_mode"
        case nameServers = "name_servers"
        case originalNameServers = "original_name_servers"
        case originalRegistrar = "original_registrar"
        case originalDnshost = "original_dnshost"
        case modifiedOn = "modified_on"
        case createdOn = "created_on"
        case activatedOn = "activated_on"
    }
}
