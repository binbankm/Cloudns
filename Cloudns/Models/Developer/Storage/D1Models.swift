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

    public var defaultValue: String? {
        dflt_value
    }

    public var isPrimaryKey: Bool {
        pk == 1
    }

    public var isNotNull: Bool {
        notnull == 1
    }

    public init(cid: Int, name: String, type: String, notnull: Int, dflt_value: String?, pk: Int) {
        self.cid = cid
        self.name = name
        self.type = type
        self.notnull = notnull
        self.dflt_value = dflt_value
        self.pk = pk
    }
}

// MARK: - D1 Table & Row Models

public struct D1ColumnInfo: Identifiable, Equatable, Sendable {
    public var id: String {
        name
    }

    public let name: String
    public let type: String
    public let notNull: Bool
    public let defaultValue: String?
    public let isPrimaryKey: Bool

    public init(
        name: String,
        type: String,
        notNull: Bool,
        defaultValue: String? = nil,
        isPrimaryKey: Bool = false
    ) {
        self.name = name
        self.type = type
        self.notNull = notNull
        self.defaultValue = defaultValue
        self.isPrimaryKey = isPrimaryKey
    }
}

public struct D1TableRow: Identifiable, Equatable, Sendable {
    public let id: String
    public let rowid: String?
    public let values: [String: String]

    public init(index: Int, values: [String: String]) {
        rowid = values["_rowid_"]
        if let rid = values["_rowid_"], !rid.isEmpty {
            id = "rowid_\(rid)"
        } else {
            id = "row_\(index)_\(abs(values.description.hashValue))"
        }
        self.values = values
    }
}

public enum D1DisplayMode: String, CaseIterable, Equatable, Sendable {
    case cards = "Cards"
    case table = "Table"
}

public struct D1RowContext: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let isEditing: Bool
    public let row: [String: String]?

    public init(id: UUID = UUID(), isEditing: Bool, row: [String: String]?) {
        self.id = id
        self.isEditing = isEditing
        self.row = row
    }

    public static var insert: D1RowContext {
        D1RowContext(isEditing: false, row: nil)
    }

    public static func edit(row: [String: String]) -> D1RowContext {
        D1RowContext(isEditing: true, row: row)
    }
}
