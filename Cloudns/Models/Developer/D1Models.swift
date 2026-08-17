import Foundation

// MARK: - D1 Database Models

public struct D1Database: Codable, Identifiable, Equatable {
    public var id: String { uuid }
    public let uuid: String
    public let name: String
    public let version: String?
    public let numTables: Int?
    public let fileSize: Int?
    public let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case uuid, name, version
        case numTables = "num_tables"
        case fileSize = "file_size"
        case createdAt = "created_at"
    }
    
    public init(uuid: String, name: String, numTables: Int? = 4, fileSize: Int? = 1048576, createdAt: String? = "2024-01-01T00:00:00Z") {
        self.uuid = uuid
        self.name = name
        self.version = "beta"
        self.numTables = numTables
        self.fileSize = fileSize
        self.createdAt = createdAt
    }
    
    public static let placeholders: [D1Database] = (0..<4).map { idx in
        D1Database(uuid: "d1-uuid-\(idx + 1)-db", name: "production-users-db-\(idx + 1)")
    }
    
    public var formattedSize: String {
        guard let size = fileSize else { return "0 B" }
        let b = Double(size)
        if b < 1024 { return "\(size) B" }
        let kb = b / 1024.0
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024.0
        return String(format: "%.2f MB", mb)
    }
}

public struct D1QueryResult: Codable, Equatable {
    public let success: Bool
    public let query: String
    public let durationMs: Double
    public let rowsRead: Int
    public let rowsWritten: Int
    public let columns: [String]
    public let rows: [[String: String]]
    public let rawJson: String?
    
    public init(success: Bool, query: String, durationMs: Double, rowsRead: Int, rowsWritten: Int, columns: [String], rows: [[String: String]], rawJson: String? = nil) {
        self.success = success
        self.query = query
        self.durationMs = durationMs
        self.rowsRead = rowsRead
        self.rowsWritten = rowsWritten
        self.columns = columns
        self.rows = rows
        self.rawJson = rawJson
    }
}

public struct D1TableColumn: Identifiable, Equatable {
    public var id: String { name }
    public let cid: Int
    public let name: String
    public let type: String
    public let notnull: Int
    public let dflt_value: String?
    public let pk: Int
    
    public init(cid: Int, name: String, type: String, notnull: Int, dflt_value: String?, pk: Int) {
        self.cid = cid
        self.name = name
        self.type = type
        self.notnull = notnull
        self.dflt_value = dflt_value
        self.pk = pk
    }
}
