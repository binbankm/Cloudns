import Foundation
import SwiftUI

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
                                        Task { await viewModel.deleteCustomDomain(domain: domain.domain) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
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
                                        Task { await viewModel.deleteCORSRule(at: index) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            } else if viewModel.isLoading {
                Section(header: Text("Public Access (r2.dev)")) {
                    Toggle("Enable r2.dev Subdomain", isOn: .constant(false))
                        .skeletonLoading(true)
                }
                Section(header: Text("Connected Custom Domains")) {
                    ForEach(R2CustomDomain.placeholders) { ph in
                        customDomainRow(ph)
                    }
                    .skeletonLoading(true)
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
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
                    CloudnsBadge((domain.status?.lowercased() == "active") ? .active(domain.status?.capitalized ?? "Active") : .warning(domain.status?.capitalized ?? "Pending"), isCompact: true)
                    
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
