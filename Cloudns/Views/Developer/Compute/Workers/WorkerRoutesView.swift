import SwiftUI

// MARK: - WorkerRoutesView
// Apple HIG Compliant Cloudflare Worker Domain & Route Management

struct WorkerRoutesView: View {
    let accountId: String
    let scriptName: String
    let fallbackRoutes: [String]
    
    @State private var customDomains: [WorkerCustomDomain] = []
    @State private var isLoading = false
    @State private var hasFetchedData = false
    @State private var errorMessage: String?
    @State private var showingAttachSheet = false
    @State private var domainToDelete: WorkerCustomDomain?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        contentView
            .navigationTitle("Domains & Routes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAttachSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Attach Custom Domain")
                }
            }
            .sheet(isPresented: $showingAttachSheet) {
                WorkerAttachDomainSheetView(accountId: accountId, scriptName: scriptName) {
                    Task { await fetchDomains() }
                }
            }
            .confirmationDialog("Detach Domain", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: domainToDelete) { dom in
                Button("Detach '\(dom.hostname)'", role: .destructive) {
                    Task {
                        do {
                            try await WorkerService.shared.detachWorkerDomain(accountId: accountId, domainId: dom.id)
                            ToastManager.shared.showSuccess("Domain Detached", icon: "trash.fill")
                            HapticManager.notification(.success)
                            await fetchDomains()
                        } catch {
                            ToastManager.shared.showError("Failed to Detach Domain")
                            HapticManager.notification(.error)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { dom in
                Text("Are you sure you want to detach custom domain '\(dom.hostname)' from Worker '\(scriptName)'?")
            }
            .refreshable {
                await fetchDomains()
            }
            .task {
                if !hasFetchedData {
                    await fetchDomains()
                }
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            // MARK: - Custom Domains
            Section(
                header: Text("Custom Domains (\(customDomains.count))"),
                footer: Text("Custom domains map directly to this Worker without requiring DNS or SSL certificate configuration.")
            ) {
                if customDomains.isEmpty {
                    Text("No custom domains attached.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(customDomains) { dom in
                        domainRow(dom)
                            .contextMenu {
                                Button {
                                    copyToClipboard(dom.hostname, toast: "Hostname Copied")
                                } label: {
                                    Label("Copy Hostname", systemImage: "doc.on.doc")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    domainToDelete = dom
                                    showingDeleteAlert = true
                                    HapticManager.impact(.medium)
                                } label: {
                                    Label("Detach Domain", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    domainToDelete = dom
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Detach", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                    }
                }
            }
            
            // MARK: - Standard Zone Routes
            if !fallbackRoutes.isEmpty {
                Section(
                    header: Text("Zone Routes (\(fallbackRoutes.count))"),
                    footer: Text("Enterprise/Zone routes pattern-matched against Cloudflare Edge requests.")
                ) {
                    ForEach(fallbackRoutes, id: \.self) { route in
                        HStack(spacing: 12) {
                            ListRowIcon(icon: "arrow.triangle.swap", color: .blue)
                            
                            Text(route)
                                .font(.caption.monospaced())
                                .foregroundStyle(.primary)
                        }
                        .padding(.vertical, 2)
                        .contextMenu {
                            Button {
                                copyToClipboard(route, toast: "Route Copied")
                            } label: {
                                Label("Copy Route Pattern", systemImage: "doc.on.doc")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listState(
            isLoading: isLoading && !hasFetchedData,
            loadingMessage: "Loading Routes…",
            isEmpty: hasFetchedData && customDomains.isEmpty && fallbackRoutes.isEmpty,
            emptyTitle: "No Routes Configured",
            emptySystemImage: "link",
            emptyDescription: "Attach a custom hostname to route requests to this Worker.",
            emptyActionTitle: "Attach Domain",
            emptyAction: { showingAttachSheet = true },
            errorMessage: (hasFetchedData && customDomains.isEmpty && fallbackRoutes.isEmpty) ? errorMessage.map { LocalizedStringKey($0) } : nil,
            retryAction: { Task { await fetchDomains() } }
        )
    }
    
    @ViewBuilder
    private func domainRow(_ dom: WorkerCustomDomain) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ListRowIcon(icon: "link", color: .teal)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(dom.hostname)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                if let zName = dom.zoneName {
                    Text(zName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
    
    private func fetchDomains() async {
        isLoading = true
        errorMessage = nil
        do {
            self.customDomains = try await WorkerService.shared.getWorkerCustomDomains(accountId: accountId, scriptName: scriptName)
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
            self.hasFetchedData = true
        }
        isLoading = false
    }
}

// MARK: - WorkerAttachDomainSheetView (Inlined & Cohesive)

struct WorkerAttachDomainSheetView: View {
    let accountId: String
    let scriptName: String
    let onAttached: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var hostname = ""
    @State private var isAttaching = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Custom Domain"), footer: Text("Enter the hostname (e.g. api.example.com) to attach to this Worker.")) {
                    TextField("api.example.com", text: $hostname)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.body.monospacedDigit())
                        .submitLabel(.done)
                }
                
                if let err = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(verbatim: err)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Attach Domain")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Attach") {
                        Task {
                            isAttaching = true
                            errorMessage = nil
                            do {
                                let trimmedHost = hostname.trimmingCharacters(in: .whitespaces)
                                let (zones, _) = (try? await ZoneService.shared.getZones()) ?? ([], nil)
                                let matchedZone = zones.first(where: { trimmedHost.hasSuffix($0.name) })
                                let targetZoneId = matchedZone?.id ?? zones.first?.id ?? ""
                                
                                try await WorkerService.shared.attachWorkerDomain(
                                    accountId: accountId,
                                    scriptName: scriptName,
                                    hostname: trimmedHost,
                                    zoneId: targetZoneId
                                )
                                HapticManager.notification(.success)
                                ToastManager.shared.showSuccess("Domain Attached", icon: "link")
                                onAttached()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.notification(.error)
                            }
                            isAttaching = false
                        }
                    }
                    .disabled(hostname.trimmingCharacters(in: .whitespaces).isEmpty || isAttaching)
                }
            }
            .interactiveDismissDisabled(isAttaching)
        }
    }
}
