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
                                .font(HIGTypography.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("https://\(domain)")
                                .font(HIGTypography.caption.monospaced())
                                .foregroundStyle(Color.higAccent)
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
                            .font(HIGTypography.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.customDomains) { domain in
                            customDomainRow(domain)
                                .contextMenu {
                                    Button {
                                        UIPasteboard.general.string = domain.domain
                                        ToastManager.shared.showCopied("Domain Copied")
                                        HIGFeedback.copied()
                                    } label: {
                                        Label("Copy Domain", systemImage: "doc.on.doc")
                                    }
                                    
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        domainToDelete = domain
                                        showingDeleteDomainConfirm = true
                                        HIGFeedback.impact(.medium)
                                    } label: {
                                        Label("Delete Custom Domain", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        domainToDelete = domain
                                        showingDeleteDomainConfirm = true
                                        HIGFeedback.impact(.medium)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(HIGColors.error)
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
                            .font(HIGTypography.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(viewModel.corsRules.enumerated()), id: \.offset) { index, rule in
                            corsRuleRow(rule)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        corsIndexToDelete = index
                                        showingDeleteCORSConfirm = true
                                        HIGFeedback.impact(.medium)
                                    } label: {
                                        Label("Delete CORS Rule", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        corsIndexToDelete = index
                                        showingDeleteCORSConfirm = true
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
                        HIGFeedback.success()
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
                        HIGFeedback.success()
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
                .higTouchTarget(44)
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
        HStack(spacing: HIGTokens.Spacing.md) {
            ListRowIcon(icon: "globe", color: .blue)
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text(domain.domain)
                    .font(HIGTypography.body)
                    .foregroundStyle(.primary)
                
                HStack(spacing: HIGTokens.Spacing.sm) {
                    HIGBadge((domain.status?.lowercased() == "active") ? .active(domain.status?.capitalized ?? "Active") : .warning(domain.status?.capitalized ?? "Pending"), isCompact: true)
                    
                    if let zone = domain.zoneId {
                        Text("• \(zone)")
                            .font(HIGTypography.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
    
    @ViewBuilder
    private func corsRuleRow(_ rule: R2CORSRule) -> some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
            HStack {
                Text("Origins: \(rule.allowedOrigins.joined(separator: ", "))")
                    .font(HIGTypography.body.weight(.semibold))
                Spacer()
                if let maxAge = rule.maxAgeSeconds {
                    Text("\(maxAge)s")
                        .font(HIGTypography.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Text("Methods: \(rule.allowedMethods.joined(separator: ", "))")
                    .font(HIGTypography.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            
            if let headers = rule.allowedHeaders, !headers.isEmpty {
                Text("Headers: \(headers.joined(separator: ", "))")
                    .font(HIGTypography.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
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
                        .font(HIGTypography.body.monospaced())
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
                        .font(HIGTypography.body.monospacedDigit())
                        .keyboardType(.numberPad)
                }
                
                if let err = errorMessage {
                    Section {
                        HStack(spacing: HIGTokens.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(HIGColors.error)
                            Text(verbatim: err)
                                .font(HIGTypography.caption)
                                .foregroundStyle(HIGColors.error)
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
                        .higTouchTarget(44)
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
                                HIGFeedback.success()
                                dismiss()
                            } else {
                                ToastManager.shared.showError("Failed to Save CORS Rule")
                                HIGFeedback.error()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(allowedMethods.isEmpty || isSaving)
                    .higTouchTarget(44)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
