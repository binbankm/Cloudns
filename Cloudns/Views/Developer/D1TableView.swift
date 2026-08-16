import Foundation
import SwiftUI
import Combine

public struct D1ColumnInfo: Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public let type: String
    public let notNull: Bool
    public let defaultValue: String?
    public let isPrimaryKey: Bool
}

@MainActor
final class D1TableViewModel: ObservableObject {
    let accountId: String
    let databaseId: String
    let tableName: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var columns: [D1ColumnInfo] = []
    @Published var rows: [[String: String]] = []
    @Published var totalRowCount: Int = 0
    @Published var currentPage: Int = 1
    @Published var pageSize: Int = 50
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(accountId: String, databaseId: String, tableName: String) {
        self.accountId = accountId
        self.databaseId = databaseId
        self.tableName = tableName
    }
    
    var totalPages: Int {
        max(1, Int(ceil(Double(totalRowCount) / Double(pageSize))))
    }
    
    func loadTable() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Fetch column metadata
            let pragmaResult = try await apiClient.executeD1Query(
                accountId: accountId,
                databaseId: databaseId,
                sql: "PRAGMA table_info(\"\(tableName)\");"
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
            let countResult = try await apiClient.executeD1Query(
                accountId: accountId,
                databaseId: databaseId,
                sql: "SELECT count(*) as count FROM \"\(tableName)\";"
            )
            if let firstCount = countResult.rows.first?["count"], let cnt = Int(firstCount) {
                self.totalRowCount = cnt
            }
            
            // 3. Fetch rows for current page
            await fetchPageRows()
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to load table schema or data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func fetchPageRows() async {
        let offset = (currentPage - 1) * pageSize
        let sql = "SELECT rowid as _rowid_, * FROM \"\(tableName)\" LIMIT \(pageSize) OFFSET \(offset);"
        do {
            let result = try await apiClient.executeD1Query(
                accountId: accountId,
                databaseId: databaseId,
                sql: sql
            )
            self.rows = result.rows
        } catch {
            self.errorMessage = "Failed to fetch rows: \(error.localizedDescription)"
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
        let sql = "DELETE FROM \"\(tableName)\" WHERE rowid = \(rowid);"
        do {
            _ = try await apiClient.executeD1Query(
                accountId: accountId,
                databaseId: databaseId,
                sql: sql
            )
            ToastManager.shared.showSuccess("Row Deleted", message: "rowid: \(rowid)")
            await loadTable()
            return true
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func insertRow(values: [String: String]) async -> Bool {
        let cols = values.keys.map { "\"\($0)\"" }.joined(separator: ", ")
        let valPlaceholders = values.values.map { v -> String in
            let escaped = v.replacingOccurrences(of: "'", with: "''")
            return "'\(escaped)'"
        }.joined(separator: ", ")
        
        let sql = "INSERT INTO \"\(tableName)\" (\(cols)) VALUES (\(valPlaceholders));"
        do {
            _ = try await apiClient.executeD1Query(
                accountId: accountId,
                databaseId: databaseId,
                sql: sql
            )
            ToastManager.shared.showSuccess("Row Inserted", message: "Added 1 row to \(tableName)")
            await loadTable()
            return true
        } catch {
            ToastManager.shared.showError("Insert Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func updateRow(rowid: String, values: [String: String]) async -> Bool {
        let setClauses = values.map { (k, v) -> String in
            let escaped = v.replacingOccurrences(of: "'", with: "''")
            return "\"\(k)\" = '\(escaped)'"
        }.joined(separator: ", ")
        
        let sql = "UPDATE \"\(tableName)\" SET \(setClauses) WHERE rowid = \(rowid);"
        do {
            _ = try await apiClient.executeD1Query(
                accountId: accountId,
                databaseId: databaseId,
                sql: sql
            )
            ToastManager.shared.showSuccess("Row Updated", message: "Saved changes to rowid: \(rowid)")
            await loadTable()
            return true
        } catch {
            ToastManager.shared.showError("Update Failed", message: error.localizedDescription)
            return false
        }
    }
}

struct D1TableView: View {
    let accountId: String
    let databaseId: String
    let tableName: String
    
    @StateObject private var viewModel: D1TableViewModel
    @State private var selectedRowForEdit: [String: String]? = nil
    @State private var showingInsertSheet = false
    @State private var rowToDelete: [String: String]? = nil
    @State private var showingDeleteAlert = false
    
    init(accountId: String, databaseId: String, tableName: String) {
        self.accountId = accountId
        self.databaseId = databaseId
        self.tableName = tableName
        _viewModel = StateObject(wrappedValue: D1TableViewModel(accountId: accountId, databaseId: databaseId, tableName: tableName))
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Table stats bar
                HStack {
                    Label("\(viewModel.columns.count) Columns", systemImage: "rectangle.split.3x1")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label("\(viewModel.totalRowCount) Total Rows", systemImage: "list.number")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                
                Divider()
                
                if viewModel.isLoading && !viewModel.hasFetchedData {
                    List {
                        ForEach(0..<6, id: \.self) { _ in
                            SkeletonRowView()
                        }
                    }
                    .listStyle(.insetGrouped)
                } else if let err = viewModel.errorMessage, !viewModel.hasFetchedData {
                    EmptyStateView.error(
                        message: LocalizedStringKey(err),
                        retryAction: { Task { await viewModel.loadTable() } }
                    )
                } else if viewModel.rows.isEmpty && viewModel.hasFetchedData {
                    EmptyStateView(
                        icon: "tablecells",
                        title: "Empty Table",
                        message: "Table '\(tableName)' has no data rows.",
                        actionTitle: "Insert Row",
                        action: { showingInsertSheet = true }
                    )
                } else {
                    ScrollView([.horizontal, .vertical]) {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            // Header Row
                            HStack(spacing: 0) {
                                Text("#")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, alignment: .leading)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 10)
                                
                                ForEach(viewModel.columns) { col in
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 4) {
                                            Text(col.name)
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.primary)
                                            if col.isPrimaryKey {
                                                Image(systemName: "key.fill")
                                                    .font(.caption2)
                                                    .foregroundStyle(.orange)
                                            }
                                        }
                                        Text(col.type)
                                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(width: 140, alignment: .leading)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 10)
                                }
                            }
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            
                            Divider()
                            
                            // Data Rows
                            ForEach(Array(viewModel.rows.enumerated()), id: \.offset) { index, row in
                                Button {
                                    selectedRowForEdit = row
                                } label: {
                                    HStack(spacing: 0) {
                                        Text(row["_rowid_"] ?? "\(index + 1)")
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                            .frame(width: 50, alignment: .leading)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 8)
                                        
                                        ForEach(viewModel.columns) { col in
                                            let cellValue = row[col.name] ?? "NULL"
                                            Text(cellValue)
                                                .font(.caption.monospaced())
                                                .foregroundStyle(cellValue == "NULL" ? .secondary : .primary)
                                                .frame(width: 140, alignment: .leading)
                                                .lineLimit(1)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 8)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .background(index % 2 == 0 ? Color(UIColor.systemBackground) : Color(UIColor.secondarySystemGroupedBackground).opacity(0.5))
                                .contextMenu {
                                    Button {
                                        selectedRowForEdit = row
                                    } label: {
                                        Label("Edit Row", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        rowToDelete = row
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete Row", systemImage: "trash")
                                    }
                                }
                                
                                Divider()
                            }
                        }
                    }
                }
                
                // Pagination Footer
                if viewModel.totalPages > 1 {
                    HStack {
                        Button {
                            Task { await viewModel.prevPage() }
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(viewModel.currentPage <= 1 || viewModel.isLoading)
                        
                        Spacer()
                        
                        Text("Page \(viewModel.currentPage) of \(viewModel.totalPages)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Button {
                            Task { await viewModel.nextPage() }
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(viewModel.currentPage >= viewModel.totalPages || viewModel.isLoading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                }
            }
        }
        .navigationTitle(tableName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingInsertSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("插入数据行")
            }
        }
        .sheet(item: Binding(
            get: { selectedRowForEdit.map { RowIdentifiable(row: $0) } },
            set: { selectedRowForEdit = $0?.row }
        )) { item in
            D1RowEditorView(
                tableName: tableName,
                columns: viewModel.columns,
                existingRow: item.row,
                onSave: { updated in
                    if let rowid = item.row["_rowid_"] {
                        return await viewModel.updateRow(rowid: rowid, values: updated)
                    }
                    return false
                }
            )
        }
        .sheet(isPresented: $showingInsertSheet) {
            D1RowEditorView(
                tableName: tableName,
                columns: viewModel.columns,
                existingRow: nil,
                onSave: { newValues in
                    await viewModel.insertRow(values: newValues)
                }
            )
        }
        .alert("Delete Row", isPresented: $showingDeleteAlert, presenting: rowToDelete) { row in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let rowid = row["_rowid_"] {
                    Task { _ = await viewModel.deleteRow(rowid: rowid) }
                }
            }
        } message: { row in
            Text("Are you sure you want to delete row with rowid \(row["_rowid_"] ?? "")?")
        }
        .refreshable {
            await viewModel.loadTable()
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.loadTable()
            }
        }
    }
}

private struct RowIdentifiable: Identifiable {
    var id: String { row["_rowid_"] ?? UUID().uuidString }
    let row: [String: String]
}
