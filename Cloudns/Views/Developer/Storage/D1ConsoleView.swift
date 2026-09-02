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
            Section(header: Text("Database Overview")) {
                HStack {
                    Text("Database Name")
                        .font(HIGTypography.body)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(database.name)
                        .font(HIGTypography.body.weight(.medium))
                        .foregroundStyle(.primary)
                }
                
                HStack {
                    Text("UUID")
                        .font(HIGTypography.body)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(database.uuid)
                        .font(HIGTypography.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = database.uuid
                        ToastManager.shared.showCopied("Database UUID Copied")
                        HIGFeedback.copied()
                    } label: {
                        Label("Copy UUID", systemImage: "doc.on.doc")
                    }
                }
                
                if database.fileSize != nil {
                    HStack {
                        Text("Storage Size")
                            .font(HIGTypography.body)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(database.formattedSize)
                            .font(HIGTypography.body.monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                }
            }
            
            // MARK: - Database Tables
            Section(header: Text("Database Tables (\(viewModel.tables.count))")) {
                if viewModel.isLoadingTables && viewModel.tables.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView("Loading Tables…")
                            .font(HIGTypography.caption)
                        Spacer()
                    }
                    .padding(.vertical, HIGTokens.Spacing.xs)
                } else if viewModel.tables.isEmpty {
                    Text("No tables found. Create a table using SQL below.")
                        .font(HIGTypography.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.tables, id: \.self) { tableName in
                        NavigationLink(destination: D1TableView(accountId: accountId, databaseId: database.uuid, tableName: tableName)) {
                            HStack(spacing: HIGTokens.Spacing.md) {
                                ListRowIcon(icon: "tablecells", color: .purple)
                                
                                Text(tableName)
                                    .font(HIGTypography.body.monospaced().weight(.medium))
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                            }
                            .padding(.vertical, HIGTokens.Spacing.xxs)
                        }
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = tableName
                                ToastManager.shared.showCopied("Table Name Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy Table Name", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                viewModel.sqlInput = "SELECT * FROM \(tableName) LIMIT 20;"
                                HIGFeedback.selection()
                            } label: {
                                Label("Query Table", systemImage: "play.circle")
                            }
                        }
                    }
                }
            }
            
            // MARK: - SQL Query Editor
            Section(header: Text("SQL Query Console")) {
                // Presets
                ScrollView(.horizontal) {
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        ForEach(viewModel.sqlPresets, id: \.name) { preset in
                            Button {
                                HIGFeedback.impact(.light)
                                viewModel.sqlInput = preset.sql
                            } label: {
                                Text(preset.name)
                                    .font(HIGTypography.caption2.weight(.medium))
                                    .padding(.horizontal, HIGTokens.Spacing.sm + 2)
                                    .padding(.vertical, HIGTokens.Spacing.xs + 1)
                                    .background(Color(.secondarySystemFill))
                                    .foregroundStyle(.purple)
                                    .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.sm, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .higTouchTarget(44)
                        }
                    }
                    .padding(.vertical, HIGTokens.Spacing.xxs)
                }
                .scrollIndicators(.hidden)
                
                TextEditor(text: $viewModel.sqlInput)
                    .font(HIGTypography.body.monospaced())
                    .frame(minHeight: 90)
                    .keyboardType(.asciiCapable)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isEditorFocused)
                
                Button {
                    isEditorFocused = false
                    HIGFeedback.impact(.medium)
                    Task {
                        await viewModel.runQuery()
                        if viewModel.queryResult != nil {
                            ToastManager.shared.showSuccess("Query Executed", icon: "checkmark.circle.fill")
                            HIGFeedback.success()
                        } else if viewModel.errorMessage != nil {
                            ToastManager.shared.showError("Query Failed")
                            HIGFeedback.error()
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isExecuting {
                            ProgressView()
                                .padding(.trailing, HIGTokens.Spacing.xs)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text("Execute SQL")
                            .font(HIGTypography.body.weight(.semibold))
                            .foregroundStyle(.purple)
                        Spacer()
                    }
                }
                .disabled(viewModel.sqlInput.isEmpty || viewModel.isExecuting)
                .higTouchTarget(44)
            }
            
            // MARK: - Results
            if let result = viewModel.queryResult {
                Section(header: HStack {
                    Text("Query Results (\(result.rows.count) rows)")
                    Spacer()
                    HIGBadge(.active("\(result.durationMs.formatted(.number.precision(.fractionLength(1)))) ms"), isCompact: true)
                }) {
                    if result.rows.isEmpty {
                        Text("Query executed successfully. 0 rows returned.")
                            .font(HIGTypography.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(result.rows.enumerated()), id: \.offset) { _, row in
                            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
                                ForEach(result.columns, id: \.self) { col in
                                    HStack(alignment: .top) {
                                        Text(col)
                                            .font(HIGTypography.caption2.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                            .frame(width: 80, alignment: .leading)
                                        
                                        Text(row[col] ?? "null")
                                            .font(HIGTypography.caption.monospaced())
                                            .foregroundStyle(row[col] == nil ? .secondary : .primary)
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.vertical, HIGTokens.Spacing.xs)
                        }
                    }
                }
            } else if let error = viewModel.errorMessage {
                Section {
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(HIGColors.error)
                        Text(verbatim: error)
                            .font(HIGTypography.subheadline)
                            .foregroundStyle(HIGColors.error)
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
