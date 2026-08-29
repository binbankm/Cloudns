import SwiftUI

// MARK: - CreateTunnelSheetView

struct CreateTunnelSheetView: View {
    @ObservedObject var viewModel: TunnelsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var tunnelName = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("Tunnel Information"),
                    footer: Text("Creates a remotely managed Cloudflare Zero Trust tunnel. Once created, install cloudflared using the generated connector token.")
                ) {
                    TextField("Tunnel Name (e.g. homelab-gateway)", text: $tunnelName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Create Tunnel")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            let success = await viewModel.createTunnel(name: tunnelName.trimmingCharacters(in: .whitespaces))
                            if success { dismiss() }
                            isCreating = false
                        }
                    }
                    .disabled(tunnelName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
            .toastContainer()
        }
    }
}
