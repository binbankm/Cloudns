import SwiftUI

struct AddEmailRuleView: View {
    @ObservedObject var viewModel: EmailRoutingViewModel
    let zoneName: String
    @Environment(\.presentationMode) var presentationMode
    
    @State private var customAddress = ""
    @State private var destinationAddress = ""
    @State private var isSubmitting = false
    
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
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        Text(zoneName.isEmpty ? "@yourdomain.com" : "@\(zoneName)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(header: Text("Destination"), footer: Text("The verified destination address where messages will be forwarded.")) {
                    if viewModel.destinations.isEmpty {
                        Text("No verified destinations available.")
                            .foregroundStyle(.red)
                    } else {
                        Picker("Forward to", selection: $destinationAddress) {
                            ForEach(viewModel.destinations.filter { $0.isVerified }) { dest in
                                Text(dest.email).tag(dest.email)
                            }
                        }
                    }
                }
            }
            .centerConstrainedWidth(maxWidth: 840)
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
                    .disabled(customAddress.trimmingCharacters(in: .whitespaces).isEmpty || destinationAddress.isEmpty || isSubmitting)
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
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            )
            .toastContainer()
        }
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
            presentationMode.wrappedValue.dismiss()
        }
    }
}
