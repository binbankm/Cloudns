import SwiftUI

struct UploadCertificateView: View {
    let zoneId: String
    @ObservedObject var viewModel: CustomCertificatesViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var certificatePEM: String = ""
    @State private var privateKeyPEM: String = ""
    @State private var isUploading = false
    @State private var uploadError: String? = nil
    
    var body: some View {
        NavigationView {
            Form {
                if let uploadError = uploadError {
                    Section {
                        Text(uploadError)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
                
                Section(header: Text("Certificate (PEM)"), footer: Text("Paste the contents of your certificate file (.pem or .crt), including the BEGIN CERTIFICATE and END CERTIFICATE tags.")) {
                    TextEditor(text: $certificatePEM)
                        .frame(height: 150)
                        .font(.system(.footnote, design: .monospaced))
                }
                
                Section(header: Text("Private Key (PEM)"), footer: Text("Paste the contents of your private key file (.key), including the BEGIN PRIVATE KEY and END PRIVATE KEY tags.")) {
                    TextEditor(text: $privateKeyPEM)
                        .frame(height: 150)
                        .font(.system(.footnote, design: .monospaced))
                }
                
                Section {
                    Button(action: upload) {
                        if isUploading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Upload Certificate")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(certificatePEM.isEmpty || privateKeyPEM.isEmpty || isUploading)
                }
            }
            .navigationTitle("Upload Certificate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func upload() {
        isUploading = true
        uploadError = nil
        
        Task {
            do {
                try await viewModel.uploadCertificate(zoneId: zoneId, certificate: certificatePEM, privateKey: privateKeyPEM)
                dismiss()
            } catch {
                uploadError = error.localizedDescription
            }
            isUploading = false
        }
    }
}
