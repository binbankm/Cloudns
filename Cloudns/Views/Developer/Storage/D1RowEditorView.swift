import SwiftUI

// MARK: - D1RowEditorView
// Apple HIG Compliant Cloudflare D1 SQL Row Editor & Insert Form

struct D1RowEditorView: View {
    @ObservedObject var viewModel: D1TableViewModel
    let existingRow: [String: String]?

    @Environment(\.dismiss) private var dismiss
    @State private var fieldValues: [String: String] = [:]
    @State private var isSaving = false

    private var isNewRow: Bool { existingRow == nil }

    private var editableColumns: [D1ColumnInfo] {
        viewModel.columns.filter { $0.name != "_rowid_" }
    }

    init(viewModel: D1TableViewModel, existingRow: [String: String]?) {
        self.viewModel = viewModel
        self.existingRow = existingRow

        var map: [String: String] = [:]
        for col in viewModel.columns {
            if let row = existingRow {
                let raw = row[col.name] ?? ""
                map[col.name] = (raw == "NULL" || raw == "<null>") ? "" : raw
            } else {
                map[col.name] = ""
            }
        }
        _fieldValues = State(initialValue: map)
    }

    var body: some View {
        NavigationStack {
            Form {
                if let rowid = existingRow?["_rowid_"] {
                    Section(header: Text("Internal Identifier")) {
                        HStack {
                            Text("rowid")
                                .font(HIGTypography.body)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(verbatim: rowid)
                                .font(HIGTypography.body.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if editableColumns.isEmpty {
                    Section {
                        Text("No editable columns detected.")
                            .font(HIGTypography.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section(
                        header: Text(isNewRow ? "New Row Values" : "Edit Column Values"),
                        footer: Text("Leave blank to use column defaults. Values are escaped before saving.")
                    ) {
                        ForEach(editableColumns) { col in
                            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
                                HStack {
                                    Text(verbatim: col.name)
                                        .font(HIGTypography.subheadline.weight(.semibold))
                                    if col.isPrimaryKey {
                                        Image(systemName: "key.fill")
                                            .font(HIGTypography.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                    Spacer()
                                    Text(verbatim: col.type)
                                        .font(HIGTypography.caption2.monospaced())
                                        .padding(.horizontal, HIGTokens.Spacing.xs + 2)
                                        .padding(.vertical, HIGTokens.Spacing.xxs)
                                        .background(Color(.secondarySystemFill))
                                        .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.xs, style: .continuous))
                                }
                                
                                TextField(
                                    "Value",
                                    text: Binding(
                                        get: { fieldValues[col.name] ?? "" },
                                        set: { fieldValues[col.name] = $0 }
                                    )
                                )
                                .font(HIGTypography.body.monospaced())
                                .keyboardType(.asciiCapable)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.done)
                                
                                if let dflt = col.defaultValue, !dflt.isEmpty, dflt != "NULL" && dflt != "<null>" {
                                    Text("Default: \(dflt)")
                                        .font(HIGTypography.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, HIGTokens.Spacing.xxs)
                        }
                    }
                }

                if let err = viewModel.errorMessage {
                    Section {
                        HStack(spacing: HIGTokens.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(HIGColors.error)
                            Text(verbatim: err)
                                .font(HIGTypography.caption)
                                .foregroundStyle(HIGColors.error)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isNewRow ? "Insert Row" : "Edit Row")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                        .higTouchTarget(44)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(isNewRow ? "Insert" : "Save") {
                            saveRow()
                        }
                        .fontWeight(.semibold)
                        .higTouchTarget(44)
                    }
                }
            }
        }
        .higToast()
    }

    private func saveRow() {
        guard !isSaving else { return }
        isSaving = true
        let snapshot = fieldValues
        Task {
            let success: Bool
            if isNewRow {
                success = await viewModel.insertRow(values: snapshot)
            } else if let rowid = existingRow?["_rowid_"] {
                success = await viewModel.updateRow(rowid: rowid, values: snapshot)
            } else {
                success = false
            }
            
            await MainActor.run {
                isSaving = false
                if success {
                    ToastManager.shared.showSuccess(isNewRow ? "Row Inserted" : "Row Updated", icon: "checkmark.circle.fill")
                    HIGFeedback.success()
                    dismiss()
                } else {
                    ToastManager.shared.showError(isNewRow ? "Failed to Insert Row" : "Failed to Update Row")
                    HIGFeedback.error()
                }
            }
        }
    }
}
