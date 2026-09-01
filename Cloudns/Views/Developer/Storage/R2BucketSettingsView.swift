import Foundation
import SwiftUI

struct R2BucketSettingsView: View {
    let accountId: String
    let bucketName: String
    @StateObject private var viewModel: R2BucketSettingsViewModel
    @State private var showingAddCORSSheet = false
    @State private var domainToDelete: R2CustomDomain?
    @State private var corsIndexToDelete: Int?
    @State private var showingDeleteDomainConfirm = false
    @State private var showingDeleteCORSConfirm = false
    
    init(accountId: String, bucketName: String) {
        self.accountId = accountId
        self.bucketName = bucketName
        _viewModel = StateObject(wrappedValue: R2BucketSettingsViewModel(accountId: accountId, bucketName: bucketName))
    }
    
    var body: some View {
        List {
            if viewModel.hasFetchedData {
                // MARK: - r2.dev Managed Domain
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
                
                // MARK: - Custom Domains
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
                            customDomainRow(domain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        domainToDelete = domain
                                        showingDeleteDomainConfirm = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                }
                
                // MARK: - CORS Rules
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
                            corsRuleRow(rule)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        corsIndexToDelete = index
                                        showingDeleteCORSConfirm = true
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
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Bucket Settings…"))
            }
        }
        .navigationTitle("Bucket Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddCORSSheet) {
            AddCORSRuleSheetView(viewModel: viewModel)
             .higToast()
        }
        .confirmationDialog("Delete Custom Domain", isPresented: $showingDeleteDomainConfirm, titleVisibility: .visible) {
            if let domain = domainToDelete {
                Button("Delete '\(domain.domain)'", role: .destructive) {
                    Task {
                        await viewModel.deleteCustomDomain(domain: domain.domain)
                        ToastManager.shared.showSuccess("Custom Domain Deleted", icon: "trash.fill")
                        domainToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                domainToDelete = nil
            }
        } message: {
            Text("Are you sure you want to disconnect this custom domain?")
        }
        .confirmationDialog("Delete CORS Rule", isPresented: $showingDeleteCORSConfirm, titleVisibility: .visible) {
            if let idx = corsIndexToDelete {
                Button("Delete CORS Rule", role: .destructive) {
                    Task {
                        await viewModel.deleteCORSRule(at: idx)
                        ToastManager.shared.showSuccess("CORS Rule Deleted", icon: "trash.fill")
                        corsIndexToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                corsIndexToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this CORS rule?")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddCORSSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add CORS Rule")
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
    
    @ViewBuilder
    private func customDomainRow(_ domain: R2CustomDomain) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(domain.domain)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    HIGBadge((domain.status?.lowercased() == "active") ? .active(domain.status?.capitalized ?? "Active") : .warning(domain.status?.capitalized ?? "Pending"), isCompact: true)
                    
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
    }
    
    @ViewBuilder
    private func corsRuleRow(_ rule: R2CORSRule) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Origins: \(rule.allowedOrigins.joined(separator: ", "))")
                    .font(.body.weight(.semibold))
                Spacer()
                if let maxAge = rule.maxAgeSeconds {
                    Text("\(maxAge)s")
                        .font(.caption2.monospacedDigit())
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
    }
}

// MARK: - AddCORSRuleSheetView (Inlined & Cohesive)

struct AddCORSRuleSheetView: View {
    @ObservedObject var viewModel: R2BucketSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var originsText = "*"
    @State private var allowedMethods: Set<String> = ["GET", "HEAD"]
    @State private var maxAgeText = "3600"
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    let allMethods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Allowed Origins"), footer: Text("Comma-separated origins (e.g. https://example.com, *).")) {
                    TextField("https://example.com, *", text: $originsText)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Allowed HTTP Methods")) {
                    ForEach(allMethods, id: \.self) { method in
                        Toggle(method, isOn: Binding(
                            get: { allowedMethods.contains(method) },
                            set: { isSelected in
                                if isSelected {
                                    allowedMethods.insert(method)
                                } else {
                                    allowedMethods.remove(method)
                                }
                            }
                        ))
                    }
                }
                
                Section(header: Text("Max Age (Seconds)")) {
                    TextField("3600", text: $maxAgeText)
                        .keyboardType(.numberPad)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(verbatim: err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add CORS Rule")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            let origins = originsText.components(separatedBy: CharacterSet(charactersIn: ",\n "))
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }
                            let rule = R2CORSRule(
                                allowedOrigins: origins.isEmpty ? ["*"] : origins,
                                allowedMethods: Array(allowedMethods),
                                allowedHeaders: ["*"],
                                maxAgeSeconds: Int(maxAgeText)
                            )
                            let success = await viewModel.saveCORSRule(rule: rule)
                            if success {
                                HIGFeedback.success()
                                dismiss()
                            } else {
                                HIGFeedback.error()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(allowedMethods.isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
