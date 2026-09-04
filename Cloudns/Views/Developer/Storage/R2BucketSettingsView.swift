import Foundation
import SwiftUI

// MARK: - R2BucketSettingsView
// Apple HIG Compliant Cloudflare R2 Bucket Configuration, Managed Domains & CORS Rules

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
                Section {
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
                } header: {
                    Text("Public Access (r2.dev)")
                } footer: {
                    Text("Allows public read access to objects in this bucket using a Cloudflare-managed r2.dev subdomain.")
                }
                
                // MARK: - Custom Domains
                Section {
                    if viewModel.customDomains.isEmpty {
                        Text("No custom domains connected.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.customDomains) { domain in
                            customDomainRow(domain)
                                .contextMenu {
                                    Button {
                                        copyToClipboard(domain.domain, toast: "Domain Copied")
                                    } label: {
                                        Label("Copy Domain", systemImage: "doc.on.doc")
                                    }
                                    
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        domainToDelete = domain
                                        showingDeleteDomainConfirm = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete Custom Domain", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        domainToDelete = domain
                                        showingDeleteDomainConfirm = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                } header: {
                    Text("Connected Custom Domains (\(viewModel.customDomains.count))")
                } footer: {
                    Text("Custom domains configured for public bucket access.")
                }
                
                // MARK: - CORS Rules
                Section {
                    if viewModel.corsRules.isEmpty {
                        Text("No CORS rules configured.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(viewModel.corsRules.enumerated()), id: \.offset) { index, rule in
                            corsRuleRow(rule)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        corsIndexToDelete = index
                                        showingDeleteCORSConfirm = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete CORS Rule", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        corsIndexToDelete = index
                                        showingDeleteCORSConfirm = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                } header: {
                    Text("CORS Rules (\(viewModel.corsRules.count))")
                } footer: {
                    Text("Cross-Origin Resource Sharing rules for browser requests.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Bucket Settings…"
        )
        .navigationTitle("Bucket Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddCORSSheet) {
            AddCORSRuleSheetView(viewModel: viewModel)
        }
        .confirmationDialog("Delete Custom Domain", isPresented: $showingDeleteDomainConfirm, titleVisibility: .visible) {
            if let domain = domainToDelete {
                Button("Delete '\(domain.domain)'", role: .destructive) {
                    Task {
                        await viewModel.deleteCustomDomain(domain: domain.domain)
                        ToastManager.shared.showSuccess("Custom Domain Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
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
                        HapticManager.notification(.success)
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
            ListRowIcon(icon: "globe", color: .blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(domain.domain)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    let isActive = domain.status?.lowercased() == "active"
                    Text((domain.status ?? "Active").capitalized)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(isActive ? .green : .orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill((isActive ? Color.green : Color.orange).opacity(0.12)))
                    
                    if let zone = domain.zoneId {
                        Text("• \(zone)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    private func corsRuleRow(_ rule: R2CORSRule) -> some View {
        VStack(alignment: .leading, spacing: 4) {
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
        .padding(.vertical, 2)
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
                Section {
                    TextField("https://example.com, *", text: $originsText)
                        .font(.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Allowed Origins")
                } footer: {
                    Text("Comma-separated origins (e.g. https://example.com, *).")
                }
                
                Section("Allowed HTTP Methods") {
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
                
                Section("Max Age (Seconds)") {
                    TextField("3600", text: $maxAgeText)
                        .font(.body.monospacedDigit())
                        .keyboardType(.numberPad)
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
                                ToastManager.shared.showSuccess("CORS Rule Saved", icon: "lock.shield.fill")
                                HapticManager.notification(.success)
                                dismiss()
                            } else {
                                ToastManager.shared.showError("Failed to Save CORS Rule")
                                HapticManager.notification(.error)
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
