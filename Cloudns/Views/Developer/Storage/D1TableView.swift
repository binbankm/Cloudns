import Foundation
import SwiftUI
import Combine

// MARK: - D1TableView

struct D1TableView: View {
    let accountId: String
    let databaseId: String
    let tableName: String
    
    @StateObject private var viewModel: D1TableViewModel
    @State private var displayMode: D1DisplayMode = .cards
    @State private var editorContext: D1RowContext?
    @State private var rowToDelete: [String: String]?
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
                    cardsView
                        .redacted(reason: .placeholder)
                } else if let err = viewModel.errorMessage, !viewModel.hasFetchedData {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(err),
                            retryAction: { Task { await viewModel.loadTable() } }
                        )
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.rows.isEmpty && viewModel.hasFetchedData {
                    HIGContentState(
                        .empty(
                            title: "Empty Table",
                            systemImage: "tablecells",
                            description: "Table '\(tableName)' has no data rows.",
                            actionTitle: "Insert Row",
                            action: { editorContext = .insert }
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
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editorContext = .insert
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Insert Row")
            }
        }
        .sheet(item: $editorContext) { context in
            D1RowEditorView(
                viewModel: viewModel,
                existingRow: context.row
            )
             .higToast()
        }
        .confirmationDialog("Delete Row", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: rowToDelete) { row in
            Button("Delete Row", role: .destructive) {
                if let rowid = row["_rowid_"] {
                    Task { _ = await viewModel.deleteRow(rowid: rowid) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { row in
            Text(verbatim: "Are you sure you want to delete row with rowid \(row["_rowid_"] ?? "")?")
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
                ForEach(viewModel.rowItems) { item in
                    let row = item.values
                    VStack(alignment: .leading, spacing: 10) {
                        // Card Header
                        HStack {
                            Label("Row #\(item.rowid ?? item.id)", systemImage: "number")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Button {
                                editorContext = .edit(row: row)
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
                                                .font(.caption2)
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                    Text(col.type)
                                        .font(.caption2.monospaced())
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
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                ForEach(Array(viewModel.rowItems.enumerated()), id: \.element.id) { index, item in
                    let row = item.values
                    Button {
                        editorContext = .edit(row: row)
                    } label: {
                        HStack(spacing: 0) {
                            Text(item.rowid ?? "\(index + 1)")
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
                            editorContext = .edit(row: row)
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
