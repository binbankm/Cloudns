import SwiftUI

// MARK: - D1ConsoleView
// Apple HIG Compliant Cloudflare D1 Serverless SQL Query Console & Schema Explorer

struct D1ConsoleView: View {
    let accountId: String
    let database: D1Database
    @StateObject private var viewModel: D1ConsoleViewModel
    @FocusState private var isEditorFocused: Bool
    
    init(accountId: String, database: D1Database) {
        self.accountId = accountId
        self.database = database
        _viewModel = StateObject(wrappedValue: D1ConsoleViewModel(accountId: accountId, database: database))
    }
    
    var body: some View {
        List {
            // MARK: - DB Summary
            Section("Database Overview") {
                HStack {
                    Text("Database Name")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(database.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                }
                
                HStack {
                    Text("UUID")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(database.uuid)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .contextMenu {
                    Button {
                        copyToClipboard(database.uuid, toast: "Database UUID Copied")
                    } label: {
                        Label("Copy UUID", systemImage: "doc.on.doc")
                    }
                }
                
                if database.fileSize != nil {
                    HStack {
                        Text("Storage Size")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(database.formattedSize)
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                }
            }
            
            // MARK: - Database Tables
            Section("Database Tables (\(viewModel.tables.count))") {
                if viewModel.isLoadingTables && viewModel.tables.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView("Loading Tables…")
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } else if viewModel.tables.isEmpty {
                    Text("No tables found. Create a table using SQL below.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.tables, id: \.self) { tableName in
                        NavigationLink {
                            D1TableView(accountId: accountId, databaseId: database.uuid, tableName: tableName)
                        } label: {
                            HStack(spacing: 12) {
                                ListRowIcon(icon: "tablecells", color: .purple)
                                
                                Text(tableName)
                                    .font(.body.monospaced().weight(.medium))
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                        .contextMenu {
                            Button {
                                copyToClipboard(tableName, toast: "Table Name Copied")
                            } label: {
                                Label("Copy Table Name", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                viewModel.sqlInput = "SELECT * FROM \(tableName) LIMIT 20;"
                                HapticManager.selection()
                            } label: {
                                Label("Query Table", systemImage: "play.circle")
                            }
                        }
                    }
                }
            }
            
            // MARK: - SQL Query Editor
            Section("SQL Query Console") {
                // Presets
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.sqlPresets, id: \.name) { preset in
                            Button {
                                HapticManager.impact(.light)
                                viewModel.sqlInput = preset.sql
                            } label: {
                                Text(preset.name)
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(.secondarySystemFill))
                                    .foregroundStyle(.purple)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
                
                TextEditor(text: $viewModel.sqlInput)
                    .font(.body.monospaced())
                    .frame(minHeight: 90)
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isEditorFocused)
                
                Button {
                    isEditorFocused = false
                    HapticManager.impact(.medium)
                    Task {
                        await viewModel.runQuery()
                        if viewModel.queryResult != nil {
                            ToastManager.shared.showSuccess("Query Executed", icon: "checkmark.circle.fill")
                            HapticManager.notification(.success)
                        } else if viewModel.errorMessage != nil {
                            ToastManager.shared.showError("Query Failed")
                            HapticManager.notification(.error)
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isExecuting {
                            ProgressView()
                                .padding(.trailing, 6)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text("Execute SQL")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.purple)
                        Spacer()
                    }
                }
                .disabled(viewModel.sqlInput.isEmpty || viewModel.isExecuting)
            }
            
            // MARK: - Results
            if let result = viewModel.queryResult {
                Section {
                    if result.rows.isEmpty {
                        Text("Query executed successfully. 0 rows returned.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(result.rows.enumerated()), id: \.offset) { _, row in
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(result.columns, id: \.self) { col in
                                    HStack(alignment: .top) {
                                        Text(col)
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                            .frame(width: 80, alignment: .leading)
                                        
                                        Text(row[col] ?? "null")
                                            .font(.caption.monospaced())
                                            .foregroundStyle(row[col] == nil ? .secondary : .primary)
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                } header: {
                    HStack {
                        Text("Query Results (\(result.rows.count) rows)")
                        Spacer()
                        Text("\(result.durationMs.formatted(.number.precision(.fractionLength(1)))) ms")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.12)))
                    }
                }
            } else if let error = viewModel.errorMessage {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(verbatim: error)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            await viewModel.fetchTables()
        }
        .navigationTitle(database.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchTables()
        }
    }
}
