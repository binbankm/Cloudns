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
                    Section("Internal Identifier") {
                        HStack {
                            Text("rowid")
                                .font(.body)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(verbatim: rowid)
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if editableColumns.isEmpty {
                    Section {
                        Text("No editable columns detected.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        ForEach(editableColumns) { col in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(verbatim: col.name)
                                        .font(.subheadline.weight(.semibold))
                                    if col.isPrimaryKey {
                                        Image(systemName: "key.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                    Spacer()
                                    Text(verbatim: col.type)
                                        .font(.caption2.monospaced())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(.secondarySystemFill))
                                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                }
                                
                                TextField(
                                    "Value",
                                    text: Binding(
                                        get: { fieldValues[col.name] ?? "" },
                                        set: { fieldValues[col.name] = $0 }
                                    )
                                )
                                .font(.body.monospaced())
                                .keyboardType(.asciiCapable)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.done)
                                
                                if let dflt = col.defaultValue, !dflt.isEmpty, dflt != "NULL" && dflt != "<null>" {
                                    Text("Default: \(dflt)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    } header: {
                        Text(isNewRow ? LocalizedStringKey("New Row Values") : LocalizedStringKey("Edit Column Values"))
                    } footer: {
                        Text("Leave blank to use column defaults. Values are escaped before saving.")
                    }
                }

                if let err = viewModel.errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(verbatim: err)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isNewRow ? LocalizedStringKey("Insert Row") : LocalizedStringKey("Edit Row"))
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(isNewRow ? LocalizedStringKey("Insert") : LocalizedStringKey("Save")) {
                            saveRow()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
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
                    ToastManager.shared.showSuccess(isNewRow ? LocalizedStringKey("Row Inserted") : LocalizedStringKey("Row Updated"), icon: "checkmark.circle.fill")
                    HapticManager.notification(.success)
                    dismiss()
                } else {
                    ToastManager.shared.showError(isNewRow ? LocalizedStringKey("Failed to Insert Row") : LocalizedStringKey("Failed to Update Row"))
                    HapticManager.notification(.error)
                }
            }
        }
    }
}
