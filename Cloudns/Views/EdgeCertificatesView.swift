import SwiftUI

struct EdgeCertificatesView: View {
    let zoneId: String
    
    @StateObject private var viewModel = EdgeCertificatesViewModel()
    
    var displayCertificates: [EdgeCertificateModel] {
        if !viewModel.hasFetchedData {
            return EdgeCertificateModel.dummyData
        }
        return viewModel.certificates
    }
    
    var body: some View {
        List {
            if viewModel.isLoading && viewModel.certificates.isEmpty {
                Section {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else if let errorMessage = viewModel.errorMessage, viewModel.certificates.isEmpty && viewModel.hasFetchedData {
                Section {
                    EmptyStateView.error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task {
                                await viewModel.fetchCertificates(zoneId: zoneId)
                            }
                        }
                    )
                }
                .listRowBackground(Color.clear)
            } else if viewModel.certificates.isEmpty && viewModel.hasFetchedData {
                Section {
                    EmptyStateView(
                        icon: "lock.shield",
                        title: "No Edge Certificates",
                        message: "No Edge Certificates found."
                    )
                }
                .listRowBackground(Color.clear)
            } else {
                Section(
                    header: Text("Universal SSL"),
                    footer: Text("Cloudflare signs and issues free SSL/TLS edge certificates for your domain and subdomains automatically.")
                ) {
                    Toggle("Enable Universal SSL", isOn: Binding(
                        get: { viewModel.isUniversalSSLEnabled },
                        set: { newValue in
                            Task { await viewModel.toggleUniversalSSL(zoneId: zoneId, enabled: newValue) }
                        }
                    ))
                }
                
                Section(header: Text("Active Certificates (\(displayCertificates.count))")) {
                    ForEach(displayCertificates) { cert in
                        EdgeCertificateCardView(certificate: cert)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if cert.type.lowercased() != "universal" {
                                    Button(role: .destructive) {
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
        .refreshable {
            await viewModel.fetchCertificates(zoneId: zoneId)
        }
        .navigationTitle("Edge Certificates")
        .navigationBarTitleDisplayMode(.inline)
        .toastContainer()
        .task {
            if viewModel.certificates.isEmpty {
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
                }
                .frame(width: 28, height: 28)
                .cornerRadius(6)
                
                Text(certificate.type.capitalized)
                    .font(.body)
                
                Spacer()
                
                Text(certificate.status)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(certificate.status == "active" ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    .foregroundStyle(certificate.status == "active" ? .green : .gray)
                    .cornerRadius(6)
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
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ dateString: String) -> String {
        if dateString == "N/A" { return dateString }
        return DateFormatters.formatISO8601ToDisplay(dateString, style: DateFormatters.dateOnly)
    }
}
