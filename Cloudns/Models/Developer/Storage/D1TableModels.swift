import Foundation

// MARK: - D1ColumnInfo

public struct D1ColumnInfo: Identifiable, Equatable, Sendable {
    public var id: String { name }
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

// MARK: - D1TableRow

public struct D1TableRow: Identifiable, Equatable, Sendable {
    public let id: String
    public let rowid: String?
    public let values: [String: String]
    
    public init(index: Int, values: [String: String]) {
        self.rowid = values["_rowid_"]
        if let rid = values["_rowid_"], !rid.isEmpty {
            self.id = "rowid_\(rid)"
        } else {
            self.id = "row_\(index)_\(abs(values.description.hashValue))"
        }
        self.values = values
    }
}

// MARK: - D1DisplayMode

public enum D1DisplayMode: String, CaseIterable, Sendable {
    case cards = "Cards"
    case table = "Table"
}

// MARK: - D1RowContext

public struct D1RowContext: Identifiable, Sendable {
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
