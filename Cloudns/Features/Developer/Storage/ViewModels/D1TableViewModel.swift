import Foundation
import SwiftUI
import Combine

// MARK: - D1TableViewModel

@MainActor
final class D1TableViewModel: BaseLoadableViewModel {
    let accountId: String
    let databaseId: String
    let tableName: String
    private let d1Service: D1ServiceProtocol
    
    @Published var columns: [D1ColumnInfo] = []
    @Published var rows: [[String: String]] = []
    @Published var rowItems: [D1TableRow] = []
    @Published var totalRowCount: Int = 0
    @Published var currentPage: Int = 1
    @Published var pageSize: Int = 50
    
    init(
        accountId: String,
        databaseId: String,
        tableName: String,
        d1Service: D1ServiceProtocol = D1Service.shared
    ) {
        self.accountId = accountId
        self.databaseId = databaseId
        self.tableName = tableName
        self.d1Service = d1Service
        super.init()
    }
    
    private func quoteIdentifier(_ id: String) -> String {
        let escaped = id.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
    
    var totalPages: Int {
        max(1, Int(ceil(Double(totalRowCount) / Double(pageSize))))
    }
    
    func loadTable() async {
        await executeLoadingTask {
            let quotedTable = self.quoteIdentifier(self.tableName)
            // 1. Fetch column metadata
            let pragmaResult = try await self.d1Service.executeD1Query(
                accountId: self.accountId,
                databaseId: self.databaseId,
                sql: "PRAGMA table_info(\(quotedTable));"
            )
            
            var fetchedCols: [D1ColumnInfo] = []
            for row in pragmaResult.rows {
                let name = row["name"] ?? ""
                let type = row["type"] ?? "TEXT"
                let notNull = (row["notnull"] == "1")
                let dflt = row["dflt_value"]
                let pk = (row["pk"] == "1" || row["pk"] == "true")
                if !name.isEmpty {
                    fetchedCols.append(D1ColumnInfo(
                        name: name,
                        type: type.uppercased(),
                        notNull: notNull,
                        defaultValue: dflt,
                        isPrimaryKey: pk
                    ))
                }
            }
            self.columns = fetchedCols
            
            // 2. Fetch row count
            let countResult = try await self.d1Service.executeD1Query(
                accountId: self.accountId,
                databaseId: self.databaseId,
                sql: "SELECT count(*) as count FROM \(quotedTable);"
            )
            if let firstCount = countResult.rows.first?["count"], let cnt = Int(firstCount) {
                self.totalRowCount = cnt
            }
            
            // 3. Fetch rows for current page
            await self.fetchPageRows()
        }
    }
    
    func fetchPageRows() async {
        let offset = (currentPage - 1) * pageSize
        let quotedTable = quoteIdentifier(tableName)
        let sql = "SELECT rowid as _rowid_, * FROM \(quotedTable) LIMIT \(pageSize) OFFSET \(offset);"
        do {
            let result = try await d1Service.executeD1Query(
                accountId: accountId,
                databaseId: databaseId,
                sql: sql
            )
            self.rows = result.rows
            self.rowItems = result.rows.enumerated().map { D1TableRow(index: $0.offset, values: $0.element) }
        } catch {
            // Fallback for WITHOUT ROWID tables
            let fallbackSql = "SELECT * FROM \(quotedTable) LIMIT \(pageSize) OFFSET \(offset);"
            if let fallbackResult = try? await d1Service.executeD1Query(
                accountId: accountId,
                databaseId: databaseId,
                sql: fallbackSql
            ) {
                self.rows = fallbackResult.rows
                self.rowItems = fallbackResult.rows.enumerated().map { D1TableRow(index: $0.offset, values: $0.element) }
            } else {
                self.errorMessage = APIError.formatCloudflareError(error.localizedDescription)
            }
        }
    }
    
    func nextPage() async {
        guard currentPage < totalPages else { return }
        currentPage += 1
        isLoading = true
        await fetchPageRows()
        isLoading = false
    }
    
    func prevPage() async {
        guard currentPage > 1 else { return }
        currentPage -= 1
        isLoading = true
        await fetchPageRows()
        isLoading = false
    }
    
    func deleteRow(rowid: String) async -> Bool {
        guard !rowid.isEmpty, rowid.allSatisfy({ $0.isNumber || $0 == "-" }) else {
            CloudnsToastManager.shared.showError("Invalid row ID", message: "rowid must be numeric.")
            return false
        }
        let quotedTable = quoteIdentifier(tableName)
        let sql = "DELETE FROM \(quotedTable) WHERE rowid = \(rowid);"
        do {
            _ = try await d1Service.executeD1Query(
                accountId: accountId,
                databaseId: databaseId,
                sql: sql
            )
            CloudnsToastManager.shared.showSuccess("Row Deleted", message: "rowid: \(rowid)")
            await loadTable()
            return true
        } catch {
            CloudnsToastManager.shared.showError("Delete Failed", message: APIError.formatCloudflareError(error.localizedDescription))
            return false
        }
    }
    
    func insertRow(values: [String: String]) async -> Bool {
        // Filter out blank values to let SQLite handle AUTOINCREMENT and DEFAULT values properly
        let activePairs = values.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let quotedTable = quoteIdentifier(tableName)
        
        let sql: String
        if activePairs.isEmpty {
            sql = "INSERT INTO \(quotedTable) DEFAULT VALUES;"
        } else {
            let cols = activePairs.map { quoteIdentifier($0.key) }.joined(separator: ", ")
            let valPlaceholders = activePairs.map { pair -> String in
                let escaped = pair.value.replacingOccurrences(of: "'", with: "''")
                return "'\(escaped)'"
            }.joined(separator: ", ")
            sql = "INSERT INTO \(quotedTable) (\(cols)) VALUES (\(valPlaceholders));"
        }
        
        do {
            _ = try await d1Service.executeD1Query(
                accountId: accountId,
                databaseId: databaseId,
                sql: sql
            )
            CloudnsToastManager.shared.showSuccess("Row Inserted", message: "Added 1 row to \(tableName)")
            await loadTable()
            return true
        } catch {
            CloudnsToastManager.shared.showError("Insert Failed", message: APIError.formatCloudflareError(error.localizedDescription))
            return false
        }
    }
    
    func updateRow(rowid: String, values: [String: String]) async -> Bool {
        guard !rowid.isEmpty, rowid.allSatisfy({ $0.isNumber || $0 == "-" }) else {
            CloudnsToastManager.shared.showError("Invalid row ID", message: "rowid must be numeric.")
            return false
        }
        let setClauses = values.map { (k, v) -> String in
            let escaped = v.replacingOccurrences(of: "'", with: "''")
            return "\"\(k)\" = '\(escaped)'"
        }.joined(separator: ", ")
        
        guard !setClauses.isEmpty else { return true }
        
        let sql = "UPDATE \"\(tableName)\" SET \(setClauses) WHERE rowid = \(rowid);"
        do {
            _ = try await d1Service.executeD1Query(
                accountId: accountId,
                databaseId: databaseId,
                sql: sql
            )
            CloudnsToastManager.shared.showSuccess("Row Updated", message: "Saved changes to rowid: \(rowid)")
            await loadTable()
            return true
        } catch {
            CloudnsToastManager.shared.showError("Update Failed", message: APIError.formatCloudflareError(error.localizedDescription))
            return false
        }
    }
}
