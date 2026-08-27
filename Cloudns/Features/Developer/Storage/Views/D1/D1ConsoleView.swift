import SwiftUI

struct D1ConsoleView: View {
    // MARK: - Properties
    let accountId: String
    let database: D1Database
    @StateObject private var viewModel: D1ConsoleViewModel
    @FocusState private var isEditorFocused: Bool
    
    init(accountId: String, database: D1Database) {
        self.accountId = accountId
        self.database = database
        _viewModel = StateObject(wrappedValue: D1ConsoleViewModel(accountId: accountId, database: database))
    }
    
    // MARK: - Body
    var body: some View {
        List {
            // MARK: - DB Summary
            Section(header: Text("Database Overview")) {
                HStack {
                    Text("Database Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(database.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
                
                HStack {
                    Text("UUID")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(database.uuid)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                
                if database.fileSize != nil {
                    HStack {
                        Text("Storage Size")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(database.formattedSize)
                            .foregroundStyle(.primary)
                    }
                }
            }
            
            // MARK: - Database Tables
            Section(header: Text("Database Tables (\(viewModel.tables.count))")) {
                if viewModel.isLoadingTables && viewModel.tables.isEmpty {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 6)
                        Text("Discovering tables...")
                            .foregroundStyle(.secondary)
                    }
                } else if viewModel.tables.isEmpty {
                    Text("No tables found. Create a table using SQL below.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.tables, id: \.self) { tableName in
                        NavigationLink(destination: D1TableView(accountId: accountId, databaseId: database.uuid, tableName: tableName)) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Color.purple.opacity(0.12)
                                    Image(systemName: "tablecells")
                                        .foregroundStyle(.purple)
                                        .font(.body)
                                        .accessibilityHidden(true)
                                }
                                .frame(width: 32, height: 32)
                                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.xxs))
                                
                                Text(tableName)
                                    .font(.body.weight(.medium))
                                
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            
            // MARK: - SQL Query Editor
            Section(header: Text("SQL Query Console")) {
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
                                    .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.xxs))
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
                
                TextEditor(text: $viewModel.sqlInput)
                    .font(.body.monospacedDigit())
                    .frame(minHeight: 80)
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isEditorFocused)
                
                Button {
                    isEditorFocused = false
                    HapticManager.impact(.medium)
                    Task { await viewModel.runQuery() }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isExecuting {
                            ProgressView()
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text("Execute SQL")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.purple)
                        Spacer()
                    }
                }
                .disabled(viewModel.sqlInput.isEmpty || viewModel.isExecuting)
            }
            
            // MARK: - Results
            if let result = viewModel.queryResult {
                Section(header: HStack {
                    Text("Query Results (\(result.rows.count) rows)")
                    Spacer()
                    CloudnsBadge(.active(String(format: "%.1f ms", result.durationMs)), isCompact: true)
                }) {
                    if result.rows.isEmpty {
                        Text("Query executed successfully. 0 rows returned.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(result.rows.enumerated()), id: \.offset) { _, row in
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(result.columns, id: \.self) { col in
                                    HStack(alignment: .top) {
                                        Text(col)
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                            .frame(width: 80, alignment: .leading)
                                        
                                        Text(row[col] ?? "null")
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(.primary)
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            } else if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .centerConstrainedWidth(maxWidth: 840)
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
