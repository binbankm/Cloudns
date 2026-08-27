import SwiftUI

// MARK: - WorkerAttachDomainSheetView

struct WorkerAttachDomainSheetView: View {
    // MARK: - Properties
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
    
    // MARK: - Body
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
                            Text("No domains found in account. Use manual entry.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Domain", selection: $selectedZoneId) {
                                ForEach(availableZones) { zone in
                                    Text(zone.name).tag(zone.id)
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Subdomain Prefix"), footer: Text("Example: 'api' for api.yourdomain.com, or leave empty / '@' for apex domain.")) {
                        TextField("Subdomain (e.g. api)", text: $subdomainPrefix)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                    }
                } else {
                    Section(header: Text("Custom Hostname"), footer: Text("Enter the full hostname you wish to attach (e.g. app.example.com).")) {
                        TextField("Hostname (e.g. worker.example.com)", text: $manualHostname)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                    }
                }
                
                if !computedHostname.isEmpty {
                    Section(header: Text("Target Hostname Preview")) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundStyle(.blue)
                                .accessibilityHidden(true)
                            Text(computedHostname)
                                .font(.body.monospaced())
                                .foregroundStyle(.primary)
                        }
                    }
                }
                
                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Attach Custom Domain")
            .navigationBarTitleDisplayMode(.inline)
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
                                try await WorkerService.shared.attachWorkerDomain(
                                    accountId: accountId,
                                    scriptName: scriptName,
                                    hostname: computedHostname,
                                    zoneId: computedZoneId
                                )
                                CloudnsToastManager.shared.showSuccess("Domain Attached", message: computedHostname)
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
            .interactiveDismissDisabled(isAttaching)
            .task {
                await loadZones()
            }
            .toastContainer()
        }
    }
    
    // MARK: - Actions
    private func loadZones() async {
        isLoadingZones = true
        do {
            let (zones, _) = try await ZoneService.shared.getZones()
            self.availableZones = zones
            if let first = zones.first, selectedZoneId.isEmpty {
                selectedZoneId = first.id
            }
            if zones.isEmpty {
                isCustomMode = true
            }
        } catch {
            isCustomMode = true
        }
        isLoadingZones = false
    }
}
