import Foundation

// MARK: - D1 Database Models

public struct D1Database: Codable, Identifiable, Equatable, Sendable {
    public var id: String {
        uuid
    }

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

    public init(uuid: String, name: String, numTables: Int? = 4, fileSize: Int? = 1_048_576, createdAt: String? = "2024-01-01T00:00:00Z") {
        self.uuid = uuid
        self.name = name
        version = "beta"
        self.numTables = numTables
        self.fileSize = fileSize
        self.createdAt = createdAt
    }

    public var formattedSize: String {
        guard let size = fileSize else { return "0 B" }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

public struct D1QueryResult: Codable, Equatable, Sendable {
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

public struct D1TableColumn: Identifiable, Equatable, Sendable {
    public var id: String {
        name
    }

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

public struct D1TableInfo: Identifiable, Equatable, Sendable {
    public var id: String { name }
    public let name: String
    public let type: String?
    public let rowCount: Int?

    public init(name: String, type: String? = "table", rowCount: Int? = nil) {
        self.name = name
        self.type = type
        self.rowCount = rowCount
    }
}

public struct D1BackupInfo: Codable, Identifiable, Equatable, Sendable {
    public var id: String { bookmarkId ?? UUID().uuidString }
    public let bookmarkId: String?
    public let timestamp: String?
    public let state: String?

    enum CodingKeys: String, CodingKey {
        case bookmarkId = "bookmark_id"
        case timestamp, state
    }

    public init(bookmarkId: String?, timestamp: String?, state: String? = "ready") {
        self.bookmarkId = bookmarkId
        self.timestamp = timestamp
        self.state = state
    }
}
