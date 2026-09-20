import SwiftUI

// MARK: - EdgeCertificatesView

// Apple HIG Compliant Cloudflare Edge Certificates & Universal SSL (iOS 16.0+)

struct EdgeCertificatesView: View {
    let zoneId: String
    var zoneName: String = ""
    var zoneTier: PlanTier = .free

    @StateObject private var viewModel = EdgeCertificatesViewModel()
    @State private var searchText = ""
    @State private var certToDelete: EdgeCertificateModel?
    @State private var showingDeleteConfirm = false
    @State private var showingUploadSheet = false
    @State private var showingUpgradeSheet = false

    private var isCustomCertUnlocked: Bool {
        zoneTier >= .business
    }

    private var activeCustomCerts: [EdgeCertificateModel] {
        viewModel.certificates.filter { $0.type.lowercased() == "custom" }
    }

    private var displayedCertificates: [EdgeCertificateModel] {
        let list = viewModel.certificates.filter { $0.type.lowercased() != "custom" }
        if searchText.isEmpty {
            return list
        }
        return list.filter {
            $0.hosts.joined(separator: " ").localizedStandardContains(searchText) ||
                $0.issuer.localizedStandardContains(searchText) ||
                $0.type.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        List {
            // MARK: - Universal SSL
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
                            ToastManager.shared.showSuccess(newValue ? LocalizedStringKey("Universal SSL Enabled") : LocalizedStringKey("Universal SSL Disabled"), icon: "lock.shield.fill")
                        }
                    }
                ))
            }

            // MARK: - Custom Certificates (Business & Enterprise)
            Section(
                header: HStack {
                    Text("Custom Certificates")
                    if !isCustomCertUnlocked {
                        PlanBadgeView(
                            title: PlanTier.business.shortBadge,
                            tintColor: PlanBadgeView.color(for: .business),
                            isUnlocked: false
                        )
                    }
                },
                footer: Text(isCustomCertUnlocked
                    ? "Upload and manage your own SSL/TLS certificates for your zone."
                    : "Custom SSL certificates require a Cloudflare Business or Enterprise plan to upload.")
            ) {
                if isCustomCertUnlocked {
                    Button {
                        HapticManager.selection()
                        showingUploadSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            ListRowIcon(icon: "plus.circle.fill", color: .orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Upload Custom Certificate")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text("Import SSL certificate with private key")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        HapticManager.notification(.warning)
                        showingUpgradeSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            ListRowIcon(icon: "person.badge.key", color: .orange)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Upload Custom Certificate")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    PlanBadgeView(
                                        title: PlanTier.business.shortBadge,
                                        tintColor: PlanBadgeView.color(for: .business),
                                        isUnlocked: false
                                    )
                                }
                                Text("Requires Business plan or higher")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                ForEach(activeCustomCerts) { cert in
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

                            Divider()

                            Button(role: .destructive) {
                                certToDelete = cert
                                showingDeleteConfirm = true
                                HapticManager.impact(.medium)
                            } label: {
                                Label("Delete Certificate", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
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

            // MARK: - Edge / Universal Certificates
            if !displayedCertificates.isEmpty {
                Section(header: Text("Edge Certificates (\(displayedCertificates.count))")) {
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
        .sheet(isPresented: $showingUpgradeSheet) {
            PlanUpgradeSheetView(
                featureName: "Custom SSL Certificates",
                currentTier: zoneTier,
                requiredTier: .business,
                zoneName: zoneName
            )
        }
        .sheet(isPresented: $showingUploadSheet) {
            UploadCustomCertificateView(zoneId: zoneId, zoneTier: zoneTier, viewModel: viewModel)
        }
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
        case "universal": "globe"
        case "advanced": "star.fill"
        case "custom": "person.badge.key"
        default: "seal.fill"
        }
    }

    var iconColor: Color {
        switch certificate.type.lowercased() {
        case "universal": .blue
        case "advanced": .purple
        case "custom": .orange
        default: .gray
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

// MARK: - UploadCustomCertificateView

struct UploadCustomCertificateView: View {
    let zoneId: String
    var zoneTier: PlanTier = .free
    @ObservedObject var viewModel: EdgeCertificatesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var certificatePEM = ""
    @State private var privateKeyPEM = ""
    @State private var bundleMethod = "ubiquitous"
    @State private var geoRestriction = "none"
    @State private var isUploading = false
    @State private var errorMessage: String?

    private var isValid: Bool {
        !certificatePEM.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !privateKeyPEM.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("SSL/TLS Certificate"),
                    footer: Text("Paste your PEM-encoded SSL/TLS certificate chain (including intermediate certificates).")
                ) {
                    TextEditor(text: $certificatePEM)
                        .font(.caption.monospaced())
                        .frame(minHeight: 120)
                }

                Section(
                    header: Text("Private Key"),
                    footer: Text("Paste your matching unencrypted RSA/ECDSA private key in PEM format.")
                ) {
                    TextEditor(text: $privateKeyPEM)
                        .font(.caption.monospaced())
                        .frame(minHeight: 100)
                }

                Section(
                    header: Text("Bundle Method"),
                    footer: Text("Ubiquitous optimizes for browser compatibility. Optimal prioritizes modern browsers.")
                ) {
                    Picker("Bundle Method", selection: $bundleMethod) {
                        Text("Ubiquitous (Compatible)").tag("ubiquitous")
                        Text("Optimal (Modern)").tag("optimal")
                        Text("Force (As Uploaded)").tag("force")
                    }
                    .pickerStyle(.menu)
                }

                Section(
                    header: HStack {
                        Text("Geo-Key Restrictions")
                        if zoneTier < .enterprise {
                            PlanBadgeView(
                                title: PlanTier.enterprise.shortBadge,
                                tintColor: PlanBadgeView.color(for: .enterprise),
                                isUnlocked: false
                            )
                        }
                    },
                    footer: Text("Restricts private key distribution to specific geographic regions (Enterprise feature).")
                ) {
                    Picker("Geo Restriction", selection: $geoRestriction) {
                        Text("None (Global Edge)").tag("none")
                        Text("United States Only (US)").tag("us")
                        Text("European Union Only (EU)").tag("eu")
                        Text("Highest Security Data Centers").tag("highest_security")
                    }
                    .pickerStyle(.menu)
                    .disabled(zoneTier < .enterprise)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Upload Custom Cert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isUploading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Upload") {
                        uploadCertificate()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid || isUploading)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func uploadCertificate() {
        guard isValid else { return }
        isUploading = true
        errorMessage = nil
        HapticManager.selection()

        Task {
            do {
                let geo: GeoRestrictions? = (geoRestriction == "none" || zoneTier < .enterprise)
                    ? nil
                    : GeoRestrictions(label: geoRestriction)

                try await viewModel.uploadCustomCertificate(
                    zoneId: zoneId,
                    certificate: certificatePEM.trimmingCharacters(in: .whitespacesAndNewlines),
                    privateKey: privateKeyPEM.trimmingCharacters(in: .whitespacesAndNewlines),
                    bundleMethod: bundleMethod,
                    geoRestrictions: geo
                )
                ToastManager.shared.showSuccess("Custom Certificate Uploaded", icon: "checkmark.seal.fill")
                HapticManager.notification(.success)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                HapticManager.notification(.error)
                isUploading = false
            }
        }
    }
}
