import SwiftUI

// MARK: - Add Cron Trigger Sheet

struct AddCronTriggerSheetView: View {
    @ObservedObject var viewModel: WorkerTriggersViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var cronExpression = "*/5 * * * *"
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private struct CronPreset: Identifiable {
        var id: String { expr }
        let name: String
        let expr: String
    }
    
    private let presets: [CronPreset] = [
        CronPreset(name: "Every 5 minutes", expr: "*/5 * * * *"),
        CronPreset(name: "Every 15 minutes", expr: "*/15 * * * *"),
        CronPreset(name: "Every hour", expr: "0 * * * *"),
        CronPreset(name: "Daily at midnight (UTC)", expr: "0 0 * * *"),
        CronPreset(name: "Daily at noon (UTC)", expr: "0 12 * * *"),
        CronPreset(name: "Weekly on Sunday", expr: "0 0 * * 0"),
        CronPreset(name: "Monthly on 1st", expr: "0 0 1 * *")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Cron Expression")) {
                    TextField("*/5 * * * *", text: $cronExpression)
                        .keyboardType(.asciiCapable)
                        .submitLabel(.done)
                        .font(.body.monospacedDigit())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Common Presets")) {
                    ForEach(presets) { preset in
                        Button {
                            HapticManager.impact(.light)
                            cronExpression = preset.expr
                        } label: {
                            HStack {
                                Text(preset.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(preset.expr)
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                if cronExpression == preset.expr {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Cron Trigger")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            do {
                                try await viewModel.addSchedule(cron: cronExpression)
                                HapticManager.impact(.medium)
                                ToastManager.shared.showSuccess("Cron Trigger Added", message: cronExpression)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isSaving = false
                        }
                    }
                    .disabled(cronExpression.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .toastContainer()
        }
    }
}
