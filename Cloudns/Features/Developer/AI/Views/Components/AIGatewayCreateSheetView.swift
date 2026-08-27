import SwiftUI

// MARK: - AIGatewayCreateSheetView

struct AIGatewayCreateSheetView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: AIGatewaysViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var gatewayId = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Gateway ID"), footer: Text("A unique slug used in the Gateway universal endpoint URL.")) {
                    TextField("my-ai-gateway", text: $gatewayId)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New AI Gateway")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            errorMessage = nil
                            do {
                                try await viewModel.createGateway(id: gatewayId.trimmingCharacters(in: .whitespaces))
                                CloudnsToastManager.shared.showSuccess("AI Gateway", message: "Gateway created successfully")
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isCreating = false
                        }
                    }
                    .disabled(gatewayId.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
            .toastContainer()
        }
    }
}
