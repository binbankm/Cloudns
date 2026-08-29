import SwiftUI

// MARK: - AddIngressRuleSheetView

struct AddIngressRuleSheetView: View {
    @ObservedObject var viewModel: TunnelDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var hostname = ""
    @State private var path = ""
    @State private var serviceURL = "http://localhost:8080"
    @State private var isSaving = false
    @FocusState private var focusedField: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Public Hostname"), footer: Text("Public domain or subdomain to route traffic from (e.g. app.my-domain.com).")) {
                    TextField("app.domain.com", text: $hostname)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: "hostname")
                    TextField("Path Prefix (Optional, e.g. /api)", text: $path)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: "path")
                        .onSubmit { focusedField = "service" }
                }
                
                Section(header: Text("Target Service"), footer: Text("Address of your local service (e.g. http://localhost:8080, tcp://localhost:22, or http_status:404).")) {
                    TextField("http://localhost:8080", text: $serviceURL)
                        .keyboardType(.URL)
                        .submitLabel(.done)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: "serviceURL")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Hostname Rule")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticManager.impact(.medium)
                        Task {
                            isSaving = true
                            let cleanHost = hostname.trimmingCharacters(in: .whitespaces)
                            let cleanPath = path.trimmingCharacters(in: .whitespaces)
                            let cleanSvc = serviceURL.trimmingCharacters(in: .whitespaces)
                            let success = await viewModel.addIngressRule(hostname: cleanHost, path: cleanPath.isEmpty ? nil : cleanPath, service: cleanSvc)
                            isSaving = false
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(hostname.trimmingCharacters(in: .whitespaces).isEmpty || serviceURL.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
    }
}
