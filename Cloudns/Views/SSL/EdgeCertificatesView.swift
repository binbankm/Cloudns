import SwiftUI

// MARK: - EdgeCertificatesView
// Apple HIG Compliant Cloudflare Edge Certificates & Universal SSL

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
                                    UIPasteboard.general.string = cert.hosts.joined(separator: ", ")
                                    ToastManager.shared.showCopied("Certificate Hosts Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy Hosts", systemImage: "doc.on.doc")
                                }
                                
                                Button {
                                    UIPasteboard.general.string = cert.id
                                    ToastManager.shared.showCopied("Certificate ID Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy Certificate ID", systemImage: "link")
                                }
                                
                                if cert.type.lowercased() != "universal" {
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        certToDelete = cert
                                        showingDeleteConfirm = true
                                        HIGFeedback.impact(.medium)
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
                                        HIGFeedback.impact(.medium)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(HIGColors.error)
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
                        HIGFeedback.success()
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
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.sm) {
            HStack {
                ListRowIcon(icon: iconName, color: iconColor)
                
                Text(certificate.type.capitalized)
                    .font(HIGTypography.body.weight(.medium))
                
                Spacer()
                
                HIGBadge(certificate.status.lowercased() == "active" ? .active : .custom(color: .secondary, text: certificate.status.capitalized), isCompact: true)
            }
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
                HStack(alignment: .top) {
                    Text("Hosts")
                        .font(HIGTypography.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 70, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                        ForEach(certificate.hosts, id: \.self) { host in
                            Text(host)
                                .font(HIGTypography.subheadline.weight(.medium))
                        }
                    }
                }
                
                HStack {
                    Text("Issuer")
                        .font(HIGTypography.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 70, alignment: .leading)
                    Text(certificate.issuer)
                        .font(HIGTypography.subheadline)
                }
                
                HStack {
                    Text("Signature")
                        .font(HIGTypography.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 70, alignment: .leading)
                    Text(certificate.signature)
                        .font(HIGTypography.subheadline.monospacedDigit())
                }
                    
                HStack {
                    Text(certificate.id)
                        .font(HIGTypography.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    expiryDateView(for: certificate.expiresOn)
                }
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
    
    @ViewBuilder
    private func expiryDateView(for dateStr: String) -> some View {
        if let date = DateFormatters.parseISO8601(dateStr) {
            if date < Date() {
                Text("Expired: \(date.displayFormatted(date: .abbreviated, time: .omitted))")
                    .font(HIGTypography.caption)
                    .foregroundStyle(HIGColors.error)
            } else {
                Text("Expires: \(date.displayFormatted(date: .abbreviated, time: .omitted))")
                    .font(HIGTypography.caption)
                    .foregroundStyle(.secondary)
            }
        } else if !dateStr.isEmpty {
            Text("Expires: \(dateStr)")
                .font(HIGTypography.caption)
                .foregroundStyle(.secondary)
        }
    }
}
