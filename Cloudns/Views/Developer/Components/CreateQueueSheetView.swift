import SwiftUI

// MARK: - CreateQueueSheetView

struct CreateQueueSheetView: View {
    @ObservedObject var viewModel: QueuesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var queueName = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Queue Name"), footer: Text("Queue names must contain only lowercase alphanumeric characters and hyphens.")) {
                    TextField("my-queue", text: $queueName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Queue")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isSubmitting = true
                            let clean = queueName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                            let success = await viewModel.createQueue(name: clean)
                            if success { dismiss() }
                            isSubmitting = false
                        }
                    }
                    .disabled(queueName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
            .interactiveDismissDisabled(isSubmitting)
            .toastContainer()
        }
    }
}
