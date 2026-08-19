import SwiftUI

struct AddDestinationAddressSheetView: View {
    @ObservedObject var viewModel: EmailRoutingViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var isSubmitting = false
    @FocusState private var isFocused: Bool
    
    var isValidEmail: Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("Destination Email"),
                    footer: Text("Cloudflare will send a verification email with an activation link to this address. You must verify it before forwarding emails to it.")
                ) {
                    TextField("name@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            if isValidEmail && !isSubmitting {
                                submit()
                            }
                        }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        submit()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Send Verification")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isValidEmail || isSubmitting)
                }
            }
            .interactiveDismissDisabled(isSubmitting)
            .onAppear { isFocused = true }
        }
    }
    
    private func submit() {
        let target = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return }
        
        isSubmitting = true
        Task {
            let success = await viewModel.addDestination(email: target)
            isSubmitting = false
            if success {
                dismiss()
            }
        }
    }
}
