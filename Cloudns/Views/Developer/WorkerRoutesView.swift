import SwiftUI

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
                ToolbarItem(placement: .navigationBarTrailing) {
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
            .alert("Detach Domain", isPresented: $showingDeleteAlert, presenting: domainToDelete) { dom in
                Button("Cancel", role: .cancel) {}
                Button("Detach", role: .destructive) {
                    Task {
                        do {
                            try await WorkerService.shared.detachWorkerDomain(accountId: accountId, domainId: dom.id)
                            ToastManager.shared.showSuccess("Domain Detached", message: dom.hostname)
                            await fetchDomains()
                        } catch {
                            ToastManager.shared.showError("Detach Failed", message: error.localizedDescription)
                        }
                    }
                }
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
                if !hasFetchedData && isLoading {
                    ForEach(WorkerCustomDomain.placeholders) { dom in
                        domainRow(dom)
                    }
                    .skeletonLoading(true)
                } else if customDomains.isEmpty {
                    Text("No custom domains attached.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(customDomains) { dom in
                        domainRow(dom)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    domainToDelete = dom
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Detach", systemImage: "trash")
                                }
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
                        HStack {
                            Image(systemName: "arrow.triangle.swap")
                                .font(.body)
                                .foregroundStyle(.blue)
                                .frame(width: 30, height: 30)
                                .background(Color.blue.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .accessibilityHidden(true)
                            
                            Text(route)
                                .font(.caption.monospaced())
                                .foregroundStyle(.primary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .overlay {
            if hasFetchedData {
                if let err = errorMessage, customDomains.isEmpty && fallbackRoutes.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(err),
                            retryAction: { Task { await fetchDomains() } }
                        )
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func domainRow(_ dom: WorkerCustomDomain) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "link")
                .font(.body)
                .foregroundStyle(.orange)
                .frame(width: 30, height: 30)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
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
        .padding(.vertical, 3)
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
