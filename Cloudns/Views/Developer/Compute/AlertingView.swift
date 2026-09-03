import Foundation
import SwiftUI

// MARK: - AlertingView
// Apple HIG Compliant Cloudflare Notification Policies & Webhook Alerts

struct AlertingView: View {
    let accountId: String
    @StateObject private var viewModel: AlertingViewModel
    @State private var selectedTab = "policies"
    @State private var policyToDelete: AlertingPolicy?
    @State private var showingDeleteAlert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: AlertingViewModel(accountId: accountId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Category", selection: $selectedTab) {
                Text("Active Policies").tag("policies")
                Text("Available Alerts").tag("available")
                Text("Webhooks").tag("webhooks")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, HIGTokens.Spacing.md)
            .padding(.vertical, HIGTokens.Spacing.sm)
            .background(Color.higGroupBackground)
            .onChange(of: selectedTab) { _ in
                HIGFeedback.selection()
            }
            
            contentList
        }
        .background(Color.higGroupBackground)
        .navigationTitle("Notification Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete Policy", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: policyToDelete) { policy in
            Button("Delete '\(policy.displayName)'", role: .destructive) {
                Task {
                    await viewModel.deletePolicy(id: policy.id)
                    ToastManager.shared.showSuccess("Policy Deleted", icon: "trash.fill")
                    HIGFeedback.success()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { policy in
            Text("Are you sure you want to delete notification policy '\(policy.displayName)'?")
        }
        .refreshable {
            await viewModel.fetchData()
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchData()
            }
        }
    }
    
    @ViewBuilder
    private var contentList: some View {
        List {
            if selectedTab == "policies" {
                if !viewModel.policies.isEmpty {
                    Section(header: Text("Configured Policies (\(viewModel.policies.count))")) {
                        ForEach(viewModel.policies) { p in
                            policyRow(p)
                                .contextMenu {
                                    Button {
                                        UIPasteboard.general.string = p.id
                                        ToastManager.shared.showCopied("Policy ID Copied")
                                        HIGFeedback.copied()
                                    } label: {
                                        Label("Copy Policy ID", systemImage: "doc.on.doc")
                                    }
                                    
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        policyToDelete = p
                                        showingDeleteAlert = true
                                        HIGFeedback.impact(.medium)
                                    } label: {
                                        Label("Delete Policy", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        policyToDelete = p
                                        showingDeleteAlert = true
                                        HIGFeedback.impact(.medium)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(HIGColors.error)
                                }
                        }
                    }
                }
            } else if selectedTab == "available" {
                Section(header: Text("Supported Alert Types (\(viewModel.availableTypes.count))")) {
                    ForEach(viewModel.availableTypes) { type in
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            Text(type.displayName ?? type.type)
                                .font(HIGTypography.body.weight(.medium))
                            if let desc = type.description {
                                Text(desc)
                                    .font(HIGTypography.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, HIGTokens.Spacing.xxs)
                    }
                }
            } else {
                if !viewModel.webhooks.isEmpty {
                    Section(header: Text("Destinations & Webhooks (\(viewModel.webhooks.count))")) {
                        ForEach(viewModel.webhooks) { h in
                            HStack(spacing: HIGTokens.Spacing.md) {
                                ListRowIcon(icon: "bell.badge.fill", color: .orange)
                                VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                                    Text(h.name ?? h.id)
                                        .font(HIGTypography.body)
                                    if let url = h.url {
                                        Text(url)
                                            .font(HIGTypography.caption2.monospaced())
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.vertical, HIGTokens.Spacing.xxs)
                            .contextMenu {
                                if let url = h.url {
                                    Button {
                                        UIPasteboard.general.string = url
                                        ToastManager.shared.showCopied("Webhook URL Copied")
                                        HIGFeedback.copied()
                                    } label: {
                                        Label("Copy Webhook URL", systemImage: "link")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Notification Policies…"))
            } else if viewModel.hasFetchedData {
                if selectedTab == "policies" && viewModel.policies.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Policies",
                            systemImage: "bell.badge.slash",
                            description: "No notification policies configured in this account."
                        )
                    )
                } else if selectedTab == "webhooks" && viewModel.webhooks.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Webhooks",
                            systemImage: "bell.badge",
                            description: "No webhook destinations configured in this account."
                        )
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func policyRow(_ p: AlertingPolicy) -> some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
            HStack {
                Text(p.displayName)
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
                HIGBadge(p.isEnabled ? .active("Active") : .custom(color: .secondary, text: "Disabled"), isCompact: true)
            }
            
            if let desc = p.description, !desc.isEmpty {
                Text(desc)
                    .font(HIGTypography.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if let type = p.alertType {
                Text(type)
                    .font(HIGTypography.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
}
