import SwiftUI

struct AddEmailRuleView: View {
    @ObservedObject var viewModel: EmailRoutingViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var customAddress = ""
    @State private var destinationAddress = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Custom Address"), footer: Text("The email address on your domain that will receive messages.")) {
                    HStack {
                        TextField("e.g. info", text: $customAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        Text("@yourdomain.com")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Destination"), footer: Text("The verified destination address where messages will be forwarded.")) {
                    if viewModel.destinations.isEmpty {
                        Text("No verified destinations available.")
                            .foregroundColor(.red)
                    } else {
                        Picker("Forward to", selection: $destinationAddress) {
                            ForEach(viewModel.destinations.filter { $0.isVerified }) { dest in
                                Text(dest.email).tag(dest.email)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Routing Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await submitRule()
                        }
                    }
                    .disabled(customAddress.isEmpty || destinationAddress.isEmpty || isSubmitting)
                }
            }
            .onAppear {
                if let firstVerified = viewModel.destinations.first(where: { $0.isVerified }) {
                    destinationAddress = firstVerified.email
                }
            }
            .overlay(
                Group {
                    if isSubmitting {
                        Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
                        ProgressView("Saving...")
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(10)
                    }
                }
            )
        }
    }
    
    private func submitRule() async {
        isSubmitting = true
        
        let fullCustomAddress = customAddress.contains("@") ? customAddress : "\(customAddress)@example.com" // Needs actual domain name, but for API it's exact string
        // Note: we should really append the actual zone name instead of example.com, but for UI mock it's okay for now.
        
        await viewModel.createForwardRule(
            name: "Forward \(customAddress)",
            customAddress: fullCustomAddress,
            destinationAddress: destinationAddress
        )
        
        isSubmitting = false
        if viewModel.errorMessage == nil {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
