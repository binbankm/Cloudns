import SwiftUI

struct CustomCertificatesView: View {
    let zoneId: String
    @StateObject private var viewModel = CustomCertificatesViewModel()
    @State private var showingUploadSheet = false
    
    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }
            
            if viewModel.certificates.isEmpty && !viewModel.isLoading {
                Section {
                    Text("No custom certificates found. Note: This feature requires Cloudflare Advanced Certificate Manager or a Business/Enterprise plan.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
            
            ForEach(viewModel.certificates) { cert in
                Section(header: Text("Certificate: \(cert.id)")) {
                    LabeledContent("Status", value: cert.status)
                    LabeledContent("Issuer", value: cert.issuer)
                    LabeledContent("Expires", value: cert.expires_on)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hosts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ForEach(cert.hosts, id: \.self) { host in
                            Text(host)
                                .font(.body)
                        }
                    }
                }
            }
        }
        .navigationTitle("Custom Certificates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingUploadSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .task {
            await viewModel.fetchCertificates(zoneId: zoneId)
        }
        .sheet(isPresented: $showingUploadSheet) {
            UploadCertificateView(zoneId: zoneId, viewModel: viewModel)
        }
    }
}
