import SwiftUI

// MARK: - EdgeCertificatesView

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
                        HIGFeedback.selection()
                        Task { await viewModel.toggleUniversalSSL(zoneId: zoneId, enabled: newValue) }
                    }
                ))
            }
            
            if !displayedCertificates.isEmpty {
                Section(header: Text("Active Certificates (\(displayedCertificates.count))")) {
                    ForEach(displayedCertificates) { cert in
                        EdgeCertificateCardView(certificate: cert)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if cert.type.lowercased() != "universal" {
                                    Button(role: .destructive) {
                                        certToDelete = cert
                                        showingDeleteConfirm = true
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
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Certificates…"))
            } else if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.certificates.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchCertificates(zoneId: zoneId) }
                            }
                        )
                    )
                } else if viewModel.certificates.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Edge Certificates",
                            systemImage: "lock.shield",
                            description: "No Edge Certificates found."
                        )
                    )
                } else if displayedCertificates.isEmpty && !searchText.isEmpty {
                    HIGContentState(.search(query: searchText))
                }
            }
        }
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

// MARK: - EdgeCertificateCardView (Inlined & Cohesive)

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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    iconColor.opacity(0.12)
                    Image(systemName: iconName)
                        .foregroundStyle(iconColor)
                        .font(.subheadline.weight(.semibold))
                        .accessibilityHidden(true)
                }
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                
                Text(certificate.type.capitalized)
                    .font(.body.weight(.medium))
                
                Spacer()
                
                HIGBadge(certificate.status.lowercased() == "active" ? .active : .custom(color: .secondary, text: certificate.status.capitalized), isCompact: true)
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
                                .font(.subheadline)
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
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    expiryDateView(for: certificate.expiresOn)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func expiryDateView(for dateStr: String) -> some View {
        if let date = DateFormatters.parseISO8601(dateStr) {
            if date < Date() {
                Text("Expired: \(date, format: Date.FormatStyle(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Expires: \(date, format: Date.FormatStyle(date: .abbreviated, time: .omitted))")
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
