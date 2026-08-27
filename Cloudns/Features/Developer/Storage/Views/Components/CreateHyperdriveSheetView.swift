import SwiftUI

// MARK: - CreateHyperdriveSheetView

struct CreateHyperdriveSheetView: View {
    @ObservedObject var viewModel: HyperdriveViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var host = ""
    @State private var port = "5432"
    @State private var database = "postgres"
    @State private var user = "postgres"
    @State private var password = ""
    @State private var scheme = "postgres"
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Configuration Name")) {
                    TextField("my-database-accelerator", text: $name)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                }
                
                Section(header: Text("Origin Connection")) {
                    Picker("Engine", selection: $scheme) {
                        Text("PostgreSQL").tag("postgres")
                    }
                    
                    TextField("Host (e.g. db.example.com)", text: $host)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                    
                    TextField("Database Name", text: $database)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    
                    TextField("User", text: $user)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Hyperdrive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isSubmitting = true
                            let p = Int(port) ?? 5432
                            let origin = HyperdriveOriginInput(host: host, port: p, database: database, user: user, password: password, scheme: scheme)
                            let payload = HyperdriveCreate(name: name, origin: origin)
                            let success = await viewModel.createConfig(payload: payload)
                            if success { dismiss() }
                            isSubmitting = false
                        }
                    }
                    .disabled(name.isEmpty || host.isEmpty || password.isEmpty || isSubmitting)
                }
            }
            .interactiveDismissDisabled(isSubmitting)
            .toastContainer()
        }
    }
}
