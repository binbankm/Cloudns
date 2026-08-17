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
        List {
            // Section: Custom Domains
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
            
            // Section: Standard Zone Routes
            if !fallbackRoutes.isEmpty {
                Section(header: Text("Bound Zone Routes (\(fallbackRoutes.count))")) {
                    ForEach(fallbackRoutes, id: \.self) { r in
                        HStack {
                            Image(systemName: "arrow.triangle.branch")
                                .foregroundStyle(.purple)
                                .font(.caption)
                                .accessibilityHidden(true)
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
        .centerConstrainedWidth(maxWidth: 840)
        .overlay {
            if !hasFetchedData && isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if hasFetchedData {
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
            self.customDomains = try await CloudflareAPIClient.shared.getWorkerCustomDomains(accountId: accountId, scriptName: scriptName)
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
            self.hasFetchedData = true
        }
        isLoading = false
    }
}

struct WorkerAttachDomainSheetView: View {
    let accountId: String
    let scriptName: String
    let onAttached: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var availableZones: [Zone] = []
    @State private var selectedZoneId: String = ""
    @State private var subdomainPrefix = "api"
    @State private var isCustomMode = false
    @State private var manualHostname = ""
    
    @State private var isLoadingZones = false
    @State private var isAttaching = false
    @State private var errorMessage: String?
    
    private var selectedZone: Zone? {
        availableZones.first(where: { $0.id == selectedZoneId })
    }
    
    private var computedHostname: String {
        if isCustomMode {
            return manualHostname.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        guard let zone = selectedZone else { return "" }
        let prefix = subdomainPrefix.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if prefix.isEmpty || prefix == "@" {
            return zone.name
        } else {
            return "\(prefix).\(zone.name)"
        }
    }
    
    private var computedZoneId: String {
        if isCustomMode {
            let host = manualHostname.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if let matched = availableZones.first(where: { host == $0.name.lowercased() || host.hasSuffix("." + $0.name.lowercased()) }) {
                return matched.id
            }
            return selectedZoneId
        }
        return selectedZoneId
    }
    
    private var isValidInput: Bool {
        if isCustomMode {
            let host = manualHostname.trimmingCharacters(in: .whitespacesAndNewlines)
            return !host.isEmpty && !computedZoneId.isEmpty
        }
        return !selectedZoneId.isEmpty && !computedHostname.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if !availableZones.isEmpty {
                    Section(header: Text("Configuration Mode")) {
                        Picker("Mode", selection: $isCustomMode) {
                            Text("Select from My Domains").tag(false)
                            Text("Manual Entry").tag(true)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                if !isCustomMode {
                    Section(header: Text("Managed Domain (Zone)")) {
                        if isLoadingZones {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 4)
                            Text("Loading domains...")
                                    .foregroundStyle(.secondary)
                            }
                        } else if availableZones.isEmpty {
                            Text("No managed domains found.")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Domain", selection: $selectedZoneId) {
                                ForEach(availableZones) { zone in
                                    Text(zone.name).tag(zone.id)
                                }
                            }
                        }
                    }
                    
                    if !availableZones.isEmpty {
                        Section(
                            header: Text("Subdomain Prefix"),
                            footer: Text("Enter a subdomain prefix (e.g. 'api' for api.\(selectedZone?.name ?? "example.com")) or leave blank / enter '@' for apex domain.")
                        ) {
                            HStack {
                                TextField("api", text: $subdomainPrefix)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                
                                if let zone = selectedZone {
                                    Text(".\(zone.name)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        Section(header: Text("Target Custom Domain")) {
                            HStack {
                                Image(systemName: "link")
                                    .foregroundStyle(.orange)
                                    .accessibilityHidden(true)
                                Text(computedHostname)
                                    .font(.body.monospaced())
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                } else {
                    Section(
                        header: Text("Custom Domain Hostname"),
                        footer: Text("Enter a domain or subdomain owned by your account (e.g. api.example.com).")
                    ) {
                        TextField("api.example.com", text: $manualHostname)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                    }
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
                                try await CloudflareAPIClient.shared.attachWorkerDomain(
                                    accountId: accountId,
                                    hostname: computedHostname,
                                    zoneId: computedZoneId,
                                    service: scriptName
                                )
                                HapticManager.impact(.medium)
                                ToastManager.shared.showSuccess("Custom Domain", message: "Attached \(computedHostname)")
                                onAttached()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isAttaching = false
                        }
                    }
                    .disabled(!isValidInput || isAttaching)
                }
            }
            .task {
                isLoadingZones = true
                if let (zones, _) = try? await CloudflareAPIClient.shared.getZones(), !zones.isEmpty {
                    self.availableZones = zones
                    if self.selectedZoneId.isEmpty, let first = zones.first {
                        self.selectedZoneId = first.id
                    }
                } else {
                    self.isCustomMode = true
                }
                isLoadingZones = false
            }
        }
    }
}
