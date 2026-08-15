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
    @State private var domainToDelete: WorkerCustomDomain? = nil
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            contentView
        }
        .navigationTitle("Domains & Routes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAttachSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("关联域名")
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
                        try await CloudflareAPIClient.shared.detachWorkerDomain(accountId: accountId, domainId: dom.id)
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
        if isLoading && !hasFetchedData {
            List {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonRowView()
                }
            }
            .listStyle(.insetGrouped)
        } else if let err = errorMessage, !hasFetchedData {
            EmptyStateView.error(
                message: LocalizedStringKey(err),
                retryAction: { Task { await fetchDomains() } }
            )
        } else {
            List {
                // Section: Custom Domains
                Section(header: Text("Custom Domains (\(customDomains.count))"), footer: Text("Custom domains map directly to this Worker without requiring DNS or SSL certificate configuration.")) {
                    if customDomains.isEmpty {
                        Text("No custom domains attached.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(customDomains) { dom in
                            HStack(alignment: .center, spacing: 12) {
                                Image(systemName: "link")
                                    .font(.body)
                                    .foregroundStyle(.orange)
                                    .frame(width: 30, height: 30)
                                    .background(Color.orange.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    domainToDelete = dom
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Detach", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                
                // Section: Standard Zone Routes
                if !fallbackRoutes.isEmpty {
                    Section(header: Text("Bound Zone Routes (\(fallbackRoutes.count))")) {
                        ForEach(fallbackRoutes, id: \.self) { r in
                            HStack {
                                Image(systemName: "arrow.triangle.branch")
                                    .foregroundStyle(.purple)
                                    .font(.caption)
                                Text(r)
                                    .font(.footnote)
                                    .foregroundStyle(.primary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
    
    private func fetchDomains() async {
        isLoading = true
        errorMessage = nil
        do {
            self.customDomains = try await CloudflareAPIClient.shared.getWorkerCustomDomains(accountId: accountId, scriptName: scriptName)
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

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
                Section(header: Text("Custom Domain Hostname"), footer: Text("Enter a domain or subdomain owned by your account (e.g. api.example.com).")) {
                    TextField("api.example.com", text: $hostname)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Attach Custom Domain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Attach") {
                        Task {
                            isAttaching = true
                            errorMessage = nil
                            do {
                                // For zoneId, pass empty or auto
                                try await CloudflareAPIClient.shared.attachWorkerDomain(
                                    accountId: accountId,
                                    hostname: hostname.trimmingCharacters(in: .whitespaces),
                                    zoneId: "",
                                    service: scriptName
                                )
                                ToastManager.shared.showSuccess("Custom Domain", message: "Domain attached successfully")
                                onAttached()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isAttaching = false
                        }
                    }
                    .disabled(hostname.trimmingCharacters(in: .whitespaces).isEmpty || isAttaching)
                }
            }
            .toastContainer()
        }
    }
}
