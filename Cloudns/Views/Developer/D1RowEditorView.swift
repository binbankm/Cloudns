import SwiftUI

struct D1RowEditorView: View {
    let tableName: String
    let columns: [D1ColumnInfo]
    let existingRow: [String: String]?
    let onSave: ([String: String]) async -> Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var fieldValues: [String: String] = [:]
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    init(tableName: String, columns: [D1ColumnInfo], existingRow: [String: String]?, onSave: @escaping ([String: String]) async -> Bool) {
        self.tableName = tableName
        self.columns = columns
        self.existingRow = existingRow
        self.onSave = onSave
    }
    
    var isNewRow: Bool {
        existingRow == nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let rowid = existingRow?["_rowid_"] {
                    Section(header: Text("Internal Identifier")) {
                        HStack {
                            Text("rowid")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(rowid)
                                .font(.body.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section(header: Text(isNewRow ? "New Row Values" : "Edit Column Values"), footer: Text("Values are sanitized and escaped before database update.")) {
                    ForEach(columns.filter { $0.name != "_rowid_" }) { col in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(col.name)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(col.type)
                                    .font(.caption2.monospaced())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(UIColor.secondarySystemFill))
                                    .cornerRadius(4)
                            }
                            
                            TextField(col.defaultValue ?? "NULL", text: Binding(
                                get: { fieldValues[col.name] ?? "" },
                                set: { fieldValues[col.name] = $0 }
                            ))
                            .font(.body.monospaced())
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isNewRow ? "Insert Row" : "Edit Row")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isNewRow ? "Insert" : "Save") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            let success = await onSave(fieldValues)
                            if success {
                                dismiss()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .onAppear {
                if let row = existingRow {
                    var initMap: [String: String] = [:]
                    for col in columns {
                        initMap[col.name] = row[col.name] ?? ""
                    }
                    self.fieldValues = initMap
                }
            }
            .toastContainer()
        }
    }
}
