import SwiftUI

// MARK: - EdgeCertificatesView
// Apple HIG Compliant Cloudflare Edge Certificates & Universal SSL (iOS 16.0+)

struct EdgeCertificatesView: View {
    let zoneId: String
    
    @StateObject private var viewModel = EdgeCertificatesViewModel()
    @State private var searchText = ""
    @State private var certToDelete: EdgeCertificateModel?
    @State private var showingDeleteConfirm = false
    
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
                        HapticManager.selection()
                        Task {
                            await viewModel.toggleUniversalSSL(zoneId: zoneId, enabled: newValue)
                            ToastManager.shared.showSuccess(newValue ? "Universal SSL Enabled" : "Universal SSL Disabled", icon: "lock.shield.fill")
                        }
                    }
                ))
            }
            
            if !displayedCertificates.isEmpty {
                Section(header: Text("Active Certificates (\(displayedCertificates.count))")) {
                    ForEach(displayedCertificates) { cert in
                        EdgeCertificateCardView(certificate: cert)
                            .contextMenu {
                                Button {
                                    copyToClipboard(cert.hosts.joined(separator: ", "), toast: "Certificate Hosts Copied")
                                } label: {
                                    Label("Copy Hosts", systemImage: "doc.on.doc")
                                }
                                
                                Button {
                                    copyToClipboard(cert.id, toast: "Certificate ID Copied")
                                } label: {
                                    Label("Copy Certificate ID", systemImage: "link")
                                }
                                
                                if cert.type.lowercased() != "universal" {
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        certToDelete = cert
                                        showingDeleteConfirm = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete Certificate", systemImage: "trash")
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if cert.type.lowercased() != "universal" {
                                    Button(role: .destructive) {
                                        certToDelete = cert
                                        showingDeleteConfirm = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
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
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Certificates"
        )
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Certificates…",
            error: viewModel.certificates.isEmpty ? viewModel.errorMessage : nil,
            isEmpty: viewModel.hasFetchedData && viewModel.certificates.isEmpty,
            empty: .init(
                title: "No Edge Certificates",
                systemImage: "lock.shield",
                description: "No Edge Certificates found."
            ),
            searchQuery: (viewModel.hasFetchedData && displayedCertificates.isEmpty && !searchText.isEmpty) ? searchText : nil,
            onRetry: {
                Task { await viewModel.fetchCertificates(zoneId: zoneId) }
            }
        )
        .refreshable {
            await viewModel.fetchCertificates(zoneId: zoneId)
        }
        .navigationTitle("Edge Certificates")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete Certificate", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            if let cert = certToDelete {
                Button("Delete Certificate", role: .destructive) {
                    Task {
                        await viewModel.deleteCertificate(zoneId: zoneId, cert: cert)
                        ToastManager.shared.showSuccess("Certificate Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                        certToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                certToDelete = nil
            }
        } message: {
            if let cert = certToDelete {
                Text("Are you sure you want to delete certificate for '\(cert.hosts.joined(separator: ", "))'?")
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchCertificates(zoneId: zoneId)
            }
        }
    }
}

// MARK: - EdgeCertificateCardView

struct EdgeCertificateCardView: View {
    let certificate: EdgeCertificateModel
    
    var iconName: String {
        switch certificate.type.lowercased() {
        case "universal": return "globe"
        case "advanced": return "star.fill"
        case "custom": return "person.badge.key"
        default: return "seal.fill"
        }
    }
    
    var iconColor: Color {
        switch certificate.type.lowercased() {
        case "universal": return .blue
        case "advanced": return .purple
        case "custom": return .orange
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ListRowIcon(icon: iconName, color: iconColor)
                
                Text(certificate.type.capitalized)
                    .font(.body.weight(.medium))
                
                Spacer()
                
                let isActive = certificate.status.lowercased() == "active"
                Text(certificate.status.capitalized)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background((isActive ? Color.green : Color.secondary).opacity(0.14))
                    .foregroundStyle(isActive ? Color.green : Color.secondary)
                    .clipShape(Capsule())
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text("Hosts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 70, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(certificate.hosts, id: \.self) { host in
                            Text(host)
                                .font(.subheadline.weight(.medium))
                        }
                    }
                }
                
                HStack {
                    Text("Issuer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 70, alignment: .leading)
                    Text(certificate.issuer)
                        .font(.subheadline)
                }
                
                HStack {
                    Text("Signature")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 70, alignment: .leading)
                    Text(certificate.signature)
                        .font(.subheadline.monospacedDigit())
                }
                    
                HStack {
                    Text(certificate.id)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    expiryDateView(for: certificate.expiresOn)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    private func expiryDateView(for dateStr: String) -> some View {
        if let date = DateFormatters.parseISO8601(dateStr) {
            if date < Date() {
                Text("Expired: \(date.displayFormatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                Text("Expires: \(date.displayFormatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else if !dateStr.isEmpty {
            Text("Expires: \(dateStr)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
