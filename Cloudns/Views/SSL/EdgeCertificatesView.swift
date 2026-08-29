import SwiftUI

struct EdgeCertificatesView: View {
    let zoneId: String
    
    @StateObject private var viewModel = EdgeCertificatesViewModel()
    @State private var searchText = ""
    
    private var displayedCertificates: [EdgeCertificateModel] {
        if searchText.isEmpty { return viewModel.certificates }
        return viewModel.certificates.filter {
            $0.hosts.joined(separator: " ").localizedStandardContains(searchText) ||
            $0.issuer.localizedStandardContains(searchText) ||
            $0.type.localizedStandardContains(searchText)
        }
    }
    
    var body: some View {
        List {
            Section(
                header: Text("Universal SSL"),
                footer: Text("Cloudflare signs and issues free SSL/TLS edge certificates for your domain and subdomains automatically.")
            ) {
                Toggle("Enable Universal SSL", isOn: Binding(
                    get: { viewModel.isUniversalSSLEnabled },
                    set: { newValue in
                        HapticManager.impact(.light)
                        Task { await viewModel.toggleUniversalSSL(zoneId: zoneId, enabled: newValue) }
                    }
                ))
            }
            
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(EdgeCertificateModel.dummyData) { placeholderCert in
                        EdgeCertificateCardView(certificate: placeholderCert)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
                .redacted(reason: .placeholder)
            } else if !displayedCertificates.isEmpty {
                Section(header: Text("Active Certificates (\(displayedCertificates.count))")) {
                    ForEach(displayedCertificates) { cert in
                        EdgeCertificateCardView(certificate: cert)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if cert.type.lowercased() != "universal" {
                                    Button(role: .destructive) {
                                        HapticManager.impact(.medium)
                                        Task { await viewModel.deleteCertificate(zoneId: zoneId, cert: cert) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search Certificates"
        )
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.certificates.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchCertificates(zoneId: zoneId) }
                            }
                        )
                    )
                } else if viewModel.certificates.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "lock.shield",
                            title: "No Edge Certificates",
                            message: "No Edge Certificates found."
                        )
                    )
                } else if displayedCertificates.isEmpty && !searchText.isEmpty {
                    StateOverlayView(
                        state: .search(
                            query: searchText,
                            clearAction: { searchText = "" }
                        )
                    )
                }
            }
        }
        .refreshable {
            await viewModel.fetchCertificates(zoneId: zoneId)
        }
        .navigationTitle("Edge Certificates")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchCertificates(zoneId: zoneId)
            }
        }
    }
}
