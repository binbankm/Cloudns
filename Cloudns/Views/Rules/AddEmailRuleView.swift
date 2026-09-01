import SwiftUI

struct AddEmailRuleView: View {
    @ObservedObject var viewModel: EmailRoutingViewModel
    let zoneName: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var customAddress = ""
    @State private var destinationAddress = ""
    @State private var isSubmitting = false
    @FocusState private var isCustomAddressFocused: Bool
    
    init(viewModel: EmailRoutingViewModel, zoneName: String = "") {
        self.viewModel = viewModel
        self.zoneName = zoneName
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Custom Address"), footer: Text("The email address on your domain that will receive messages.")) {
                    HStack {
                        TextField("e.g. info", text: $customAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .focused($isCustomAddressFocused)
                        Text(zoneName.isEmpty ? "@yourdomain.com" : "@\(zoneName)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(header: Text("Destination"), footer: Text("The verified destination address where messages will be forwarded.")) {
                    if viewModel.destinations.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text("No verified destinations available.")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                    } else {
                        Picker("Forward to", selection: $destinationAddress) {
                            ForEach(viewModel.destinations.filter { $0.isVerified }) { dest in
                                Text(verbatim: dest.email).tag(dest.email)
                            }
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Routing Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HIGFeedback.impact(.medium)
                        Task {
                            await submitRule()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(customAddress.trimmingCharacters(in: .whitespaces).isEmpty || destinationAddress.isEmpty || isSubmitting)
                }
            }
            .interactiveDismissDisabled(isSubmitting)
            .onAppear {
                if let firstVerified = viewModel.destinations.first(where: { $0.isVerified }) {
                    destinationAddress = firstVerified.email
                }
            }
            .overlay(
                Group {
                    if isSubmitting {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("Saving…")
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            )
        }
        .higToast()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func submitRule() async {
        isSubmitting = true
        
        let trimmedCustom = customAddress.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let fullCustomAddress: String
        if trimmedCustom.contains("@") {
            fullCustomAddress = trimmedCustom
        } else if !zoneName.isEmpty {
            fullCustomAddress = "\(trimmedCustom)@\(zoneName)"
        } else {
            fullCustomAddress = trimmedCustom
        }
        
        await viewModel.createForwardRule(
            name: "Forward \(trimmedCustom)",
            customAddress: fullCustomAddress,
            destinationAddress: destinationAddress
        )
        
        isSubmitting = false
        if viewModel.errorMessage == nil {
            HIGFeedback.success()
            ToastManager.shared.showSuccess("Email Rule Created", icon: "envelope.fill")
            dismiss()
        } else {
            HIGFeedback.error()
        }
    }
}
