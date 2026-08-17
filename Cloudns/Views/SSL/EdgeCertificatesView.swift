import SwiftUI

struct EdgeCertificatesView: View {
    let zoneId: String
    
    @StateObject private var viewModel = EdgeCertificatesViewModel()
    
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
            
            if !viewModel.certificates.isEmpty {
                Section(header: Text("Active Certificates (\(viewModel.certificates.count))")) {
                    ForEach(viewModel.certificates) { cert in
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
        .centerConstrainedWidth(maxWidth: 840)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.hasFetchedData {
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    iconColor.opacity(0.15)
                    Image(systemName: iconName)
                        .foregroundStyle(iconColor)
                        .font(.body)
                        .accessibilityHidden(true)
                }
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Text(certificate.type.capitalized)
                    .font(.body.weight(.medium))
                
                Spacer()
                
                CloudnsBadge(certificate.status.lowercased() == "active" ? .active("Active") : .custom(color: .secondary, text: certificate.status.capitalized), isCompact: true)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text("Hosts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 4) {
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
                        .frame(width: 80, alignment: .leading)
                    Text(certificate.issuer)
                        .font(.subheadline)
                }
                
                HStack {
                    Text("Signature")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .leading)
                    Text(certificate.signature)
                        .font(.subheadline.monospacedDigit())
                }
                    
                HStack {
                    Text(certificate.id)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    Text(formatDate(certificate.expiresOn))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ dateString: String) -> String {
        if dateString == "N/A" { return dateString }
        return DateFormatters.formatISO8601ToDisplay(dateString, style: DateFormatters.dateOnly)
    }
}
