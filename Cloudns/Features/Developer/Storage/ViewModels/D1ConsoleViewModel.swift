import Foundation
import SwiftUI
import Combine

@MainActor
final class D1ConsoleViewModel: BaseLoadableViewModel {
    // MARK: - Private Properties
    let accountId: String
    let database: D1Database
    private let d1Service: D1ServiceProtocol
    
    // MARK: - Published Properties
    @Published var tables: [String] = []
    @Published var sqlInput: String = "SELECT name, type FROM sqlite_master WHERE type='table';"
    @Published var queryResult: D1QueryResult?
    @Published var isExecuting = false
    @Published var isLoadingTables = false
    
    let sqlPresets: [(name: String, sql: String)] = [
        ("Table List", "SELECT name, type FROM sqlite_master WHERE type='table';"),
        ("All Sequences", "SELECT * FROM sqlite_sequence;"),
        ("Table Info", "PRAGMA table_list;")
    ]
    
    // MARK: - Lifecycle / Init
    init(accountId: String, database: D1Database, d1Service: D1ServiceProtocol = D1Service.shared) {
        self.accountId = accountId
        self.database = database
        self.d1Service = d1Service
        super.init()
    }
    
    // MARK: - Public Methods
    func fetchTables() async {
        isLoadingTables = true
        do {
            let sql = "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '_cf_%' ORDER BY name;"
            let res = try await d1Service.executeD1Query(accountId: accountId, databaseId: database.uuid, sql: sql)
            self.tables = res.rows.compactMap { $0["name"] }
        } catch {
            self.tables = []
        }
        isLoadingTables = false
    }
    
    func runQuery() async {
        let trimmed = sqlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isExecuting = true
        errorMessage = nil
        
        do {
            self.queryResult = try await d1Service.executeD1Query(accountId: accountId, databaseId: database.uuid, sql: trimmed)
            if trimmed.localizedStandardContains("CREATE TABLE") || trimmed.localizedStandardContains("DROP TABLE") {
                await fetchTables()
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isExecuting = false
    }
}
