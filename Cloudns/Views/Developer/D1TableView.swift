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
final class D1TableViewModel: BaseLoadableViewModel {
    let accountId: String
    let databaseId: String
    let tableName: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var columns: [D1ColumnInfo] = []
    @Published var rows: [[String: String]] = []
    @Published var totalRowCount: Int = 0
    @Published var currentPage: Int = 1
    @Published var pageSize: Int = 50
    
    init(accountId: String, databaseId: String, tableName: String) {
        self.accountId = accountId
        self.databaseId = databaseId
        self.tableName = tableName
        super.init()
    }
    
    var totalPages: Int {
        max(1, Int(ceil(Double(totalRowCount) / Double(pageSize))))
    }
    
    func loadTable() async {
        await executeLoadingTask {
            // 1. Fetch column metadata
            let pragmaResult = try await self.apiClient.executeD1Query(
                accountId: self.accountId,
                databaseId: self.databaseId,
                sql: "PRAGMA table_info(\"\(self.tableName)\");"
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
            let countResult = try await self.apiClient.executeD1Query(
                accountId: self.accountId,
                databaseId: self.databaseId,
                sql: "SELECT count(*) as count FROM \"\(self.tableName)\";"
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
        let sql = "SELECT rowid as _rowid_, * FROM \"\(tableName)\" LIMIT \(pageSize) OFFSET \(offset);"
        do {
            let result = try await apiClient.executeD1Query(
                accountId: accountId,
                databaseId: databaseId,
                sql: sql
            )
            self.rows = result.rows
        } catch {
            self.errorMessage = error.localizedDescription
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
        guard !values.isEmpty else { return false }
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

public enum D1DisplayMode: String, CaseIterable {
    case cards = "Cards"
    case table = "Table"
}

struct D1TableView: View {
    let accountId: String
    let databaseId: String
    let tableName: String
    
    @StateObject private var viewModel: D1TableViewModel
    @State private var displayMode: D1DisplayMode = .cards
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
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Table stats & Display Mode Bar
                HStack(spacing: 12) {
                    Label("\(viewModel.columns.count) Columns", systemImage: "rectangle.split.3x1")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Picker("View", selection: $displayMode) {
                        Image(systemName: "rectangle.grid.1x2.fill").tag(D1DisplayMode.cards)
                        Image(systemName: "tablecells.fill").tag(D1DisplayMode.table)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 90)
                    
                    Spacer()
                    
                    Label("\(viewModel.totalRowCount) Total Rows", systemImage: "list.number")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
                
                Divider()
                
                if viewModel.isLoading && !viewModel.hasFetchedData {
                    List {
                        ForEach(0..<6, id: \.self) { _ in
                            SkeletonRowView()
                        }
                    }
                    .listStyle(.insetGrouped)
                } else if let err = viewModel.errorMessage, !viewModel.hasFetchedData {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(err),
                            retryAction: { Task { await viewModel.loadTable() } }
                        )
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.rows.isEmpty && viewModel.hasFetchedData {
                    StateOverlayView(
                        state: .empty(
                            icon: "tablecells",
                            title: "Empty Table",
                            message: "Table '\(tableName)' has no data rows.",
                            actionTitle: "Insert Row",
                            action: { showingInsertSheet = true }
                        )
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    if displayMode == .cards {
                        cardsView
                    } else {
                        tableView
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
                    .background(Color(.secondarySystemGroupedBackground))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
                .accessibilityLabel("Insert Row")
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
        .confirmationDialog("Delete Row", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: rowToDelete) { row in
            Button("Delete Row #\(row["_rowid_"] ?? "")", role: .destructive) {
                if let rowid = row["_rowid_"] {
                    Task { _ = await viewModel.deleteRow(rowid: rowid) }
                }
            }
            Button("Cancel", role: .cancel) {}
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
    
    // MARK: - 1. Cards View (纵向全屏卡片视图，无需左右滑动)
    private var cardsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.rows.enumerated()), id: \.offset) { index, row in
                    VStack(alignment: .leading, spacing: 10) {
                        // Card Header
                        HStack {
                            Label("Row #\(row["_rowid_"] ?? "\(index + 1)")", systemImage: "number")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Button {
                                selectedRowForEdit = row
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                            
                            Button(role: .destructive) {
                                rowToDelete = row
                                showingDeleteAlert = true
                            } label: {
                                Image(systemName: "trash.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.red.opacity(0.85))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Divider()
                        
                        // Field Rows
                        ForEach(viewModel.columns) { col in
                            HStack(alignment: .top, spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(col.name)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        if col.isPrimaryKey {
                                            Image(systemName: "key.fill")
                                                .font(.system(size: 9))
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                    Text(col.type)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(width: 100, alignment: .leading)
                                
                                Spacer()
                                
                                let cellVal = row[col.name] ?? "NULL"
                                Text(cellVal)
                                    .font(.callout.monospaced())
                                    .foregroundStyle(cellVal == "NULL" ? .secondary : .primary)
                                    .multilineTextAlignment(.trailing)
                                    .textSelection(.enabled)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - 2. Table Grid View (经典网格表格视图)
    private var tableView: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
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
                                .font(.caption2.monospaced().weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 140, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 10)
                    }
                }
                .background(Color(.tertiarySystemGroupedBackground))
                
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
                    .background(index % 2 == 0 ? Color(.systemBackground) : Color(.secondarySystemGroupedBackground).opacity(0.5))
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct RowIdentifiable: Identifiable {
    var id: String { row["_rowid_"] ?? UUID().uuidString }
    let row: [String: String]
}
