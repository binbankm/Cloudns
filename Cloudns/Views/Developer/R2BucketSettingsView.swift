import Foundation
import SwiftUI
import Combine

@MainActor
final class R2BucketSettingsViewModel: ObservableObject {
    let accountId: String
    let bucketName: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var managedDomain: R2ManagedDomain?
    @Published var customDomains: [R2CustomDomain] = []
    @Published var corsRules: [R2CORSRule] = []
    
    @Published var isManagedDomainEnabled: Bool = false
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    init(accountId: String, bucketName: String) {
        self.accountId = accountId
        self.bucketName = bucketName
    }
    
    func fetchSettings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let fetchManaged = apiClient.getR2ManagedDomain(accountId: accountId, bucketName: bucketName)
            async let fetchCustom = apiClient.getR2CustomDomains(accountId: accountId, bucketName: bucketName)
            async let fetchCORS = apiClient.getR2CORS(accountId: accountId, bucketName: bucketName)
            
            let (managed, custom, cors) = try await (fetchManaged, fetchCustom, fetchCORS)
            self.managedDomain = managed
            self.isManagedDomainEnabled = managed.enabled ?? false
            self.customDomains = custom
            self.corsRules = cors
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to load bucket settings: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func toggleManagedDomain(enabled: Bool) async {
        isManagedDomainEnabled = enabled
        do {
            try await apiClient.setR2ManagedDomain(accountId: accountId, bucketName: bucketName, enabled: enabled)
            ToastManager.shared.showSuccess("Managed Domain Updated", message: enabled ? "r2.dev access enabled" : "r2.dev access disabled")
            await fetchSettings()
        } catch {
            isManagedDomainEnabled = !enabled
            ToastManager.shared.showError("Update Failed", message: error.localizedDescription)
        }
    }
    
    func deleteCustomDomain(domain: String) async {
        do {
            try await apiClient.deleteR2CustomDomain(accountId: accountId, bucketName: bucketName, domain: domain)
            ToastManager.shared.showSuccess("Domain Removed", message: domain)
            await fetchSettings()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
    
    func saveCORSRule(rule: R2CORSRule) async -> Bool {
        var updated = corsRules
        updated.append(rule)
        do {
            try await apiClient.putR2CORS(accountId: accountId, bucketName: bucketName, rules: updated)
            ToastManager.shared.showSuccess("CORS Rule Added", message: "Allowed origins: \(rule.allowedOrigins.joined(separator: ", "))")
            await fetchSettings()
            return true
        } catch {
            ToastManager.shared.showError("Save Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deleteCORSRule(at index: Int) async {
        var updated = corsRules
        guard index < updated.count else { return }
        updated.remove(at: index)
        do {
            if updated.isEmpty {
                try await apiClient.deleteR2CORS(accountId: accountId, bucketName: bucketName)
            } else {
                try await apiClient.putR2CORS(accountId: accountId, bucketName: bucketName, rules: updated)
            }
            ToastManager.shared.showSuccess("CORS Rule Removed", message: "")
            await fetchSettings()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}

struct R2BucketSettingsView: View {
    let accountId: String
    let bucketName: String
    @StateObject private var viewModel: R2BucketSettingsViewModel
    @State private var showingAddCORSSheet = false
    
    init(accountId: String, bucketName: String) {
        self.accountId = accountId
        self.bucketName = bucketName
        _viewModel = StateObject(wrappedValue: R2BucketSettingsViewModel(accountId: accountId, bucketName: bucketName))
    }
    
    var body: some View {
        List {
            if viewModel.isLoading && !viewModel.hasFetchedData {
                Section {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else {
                // Section 1: r2.dev Managed Domain
                Section(
                    header: Text("Public Access (r2.dev)"),
                    footer: Text("Allows public read access to objects in this bucket using a Cloudflare-managed r2.dev subdomain.")
                ) {
                    Toggle("Enable r2.dev Subdomain", isOn: Binding(
                        get: { viewModel.isManagedDomainEnabled },
                        set: { newValue in
                            Task { await viewModel.toggleManagedDomain(enabled: newValue) }
                        }
                    ))
                    
                    if viewModel.isManagedDomainEnabled, let domain = viewModel.managedDomain?.domain {
                        HStack {
                            Text("Public URL")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("https://\(domain)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                // Section 2: Custom Domains
                Section(
                    header: Text("Connected Custom Domains (\(viewModel.customDomains.count))"),
                    footer: Text("Custom domains configured for public bucket access.")
                ) {
                    if viewModel.customDomains.isEmpty {
                        Text("No custom domains connected.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.customDomains) { domain in
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                                    .frame(width: 28)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(domain.domain)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    HStack(spacing: 8) {
                                        HStack(spacing: 4) {
                                            Circle()
                                                .fill((domain.status?.lowercased() == "active") ? Color.green : Color.orange)
                                                .frame(width: 6, height: 6)
                                            Text(domain.status?.capitalized ?? "Active")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        if let zone = domain.zoneId {
                                            Text("• \(zone)")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 3)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteCustomDomain(domain: domain.domain) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                
                // Section 3: CORS Rules
                Section(
                    header: Text("CORS Rules (\(viewModel.corsRules.count))"),
                    footer: Text("Cross-Origin Resource Sharing rules for browser requests.")
                ) {
                    if viewModel.corsRules.isEmpty {
                        Text("No CORS rules configured.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(viewModel.corsRules.enumerated()), id: \.offset) { index, rule in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Origins: \(rule.allowedOrigins.joined(separator: ", "))")
                                        .font(.body.weight(.semibold))
                                    Spacer()
                                    if let maxAge = rule.maxAgeSeconds {
                                        Text("\(maxAge)s")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                HStack {
                                    Text("Methods: \(rule.allowedMethods.joined(separator: ", "))")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                
                                if let headers = rule.allowedHeaders, !headers.isEmpty {
                                    Text("Headers: \(headers.joined(separator: ", "))")
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteCORSRule(at: index) }
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
        .navigationTitle("Bucket Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddCORSSheet) {
            AddCORSRuleSheetView(viewModel: viewModel)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddCORSSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable {
            await viewModel.fetchSettings()
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchSettings()
            }
        }
    }
}

struct AddCORSRuleSheetView: View {
    @ObservedObject var viewModel: R2BucketSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var originText = "*"
    @State private var selectedMethods: Set<String> = ["GET", "HEAD"]
    @State private var headersText = "*"
    @State private var maxAgeSeconds = 3600
    @State private var isSaving = false
    
    let allMethods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Allowed Origins"), footer: Text("Comma-separated origins (e.g. https://example.com, *)")) {
                    TextField("https://example.com or *", text: $originText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Allowed HTTP Methods")) {
                    ForEach(allMethods, id: \.self) { method in
                        Toggle(method, isOn: Binding(
                            get: { selectedMethods.contains(method) },
                            set: { isSelected in
                                if isSelected { selectedMethods.insert(method) }
                                else { selectedMethods.remove(method) }
                            }
                        ))
                    }
                }
                
                Section(header: Text("Allowed Headers"), footer: Text("Comma-separated headers (e.g. Content-Type, Authorization, *)")) {
                    TextField("Content-Type or *", text: $headersText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Max-Age (Seconds)")) {
                    Stepper("\(maxAgeSeconds) seconds", value: $maxAgeSeconds, in: 0...86400, step: 300)
                }
            }
            .navigationTitle("New CORS Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            let origins = originText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                            let headers = headersText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                            let rule = R2CORSRule(
                                allowedOrigins: origins.isEmpty ? ["*"] : origins,
                                allowedMethods: Array(selectedMethods),
                                allowedHeaders: headers.isEmpty ? nil : headers,
                                exposeHeaders: nil,
                                maxAgeSeconds: maxAgeSeconds
                            )
                            let success = await viewModel.saveCORSRule(rule: rule)
                            if success { dismiss() }
                            isSaving = false
                        }
                    }
                    .disabled(selectedMethods.isEmpty || originText.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .toastContainer()
        }
    }
}
