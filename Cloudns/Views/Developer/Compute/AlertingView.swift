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
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(uiColor: .systemGroupedBackground))
            .onChange(of: selectedTab) { _ in
                HapticManager.selection()
            }
            
            contentList
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Notification Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete Policy", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: policyToDelete) { policy in
            Button("Delete '\(policy.displayName)'", role: .destructive) {
                Task {
                    await viewModel.deletePolicy(id: policy.id)
                    ToastManager.shared.showSuccess("Policy Deleted", icon: "trash.fill")
                    HapticManager.notification(.success)
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
                                        copyToClipboard(p.id, toast: "Policy ID Copied")
                                    } label: {
                                        Label("Copy Policy ID", systemImage: "doc.on.doc")
                                    }
                                    
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        policyToDelete = p
                                        showingDeleteAlert = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete Policy", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        policyToDelete = p
                                        showingDeleteAlert = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                }
            } else if selectedTab == "available" {
                Section(header: Text("Supported Alert Types (\(viewModel.availableTypes.count))")) {
                    ForEach(viewModel.availableTypes) { type in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.displayName ?? type.type)
                                .font(.body.weight(.medium))
                            if let desc = type.description {
                                Text(desc)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            } else {
                if !viewModel.webhooks.isEmpty {
                    Section(header: Text("Destinations & Webhooks (\(viewModel.webhooks.count))")) {
                        ForEach(viewModel.webhooks) { h in
                            HStack(spacing: 12) {
                                ListRowIcon(icon: "bell.badge.fill", color: .orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(h.name ?? h.id)
                                        .font(.body)
                                    if let url = h.url {
                                        Text(url)
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                            .contextMenu {
                                if let url = h.url {
                                    Button {
                                        copyToClipboard(url, toast: "Webhook URL Copied")
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
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Notification Policies…",
            isEmpty: viewModel.hasFetchedData && (
                (selectedTab == "policies" && viewModel.policies.isEmpty) ||
                (selectedTab == "webhooks" && viewModel.webhooks.isEmpty)
            ),
            emptyTitle: selectedTab == "policies" ? "No Policies" : "No Webhooks",
            emptySystemImage: selectedTab == "policies" ? "bell.badge.slash" : "bell.badge",
            emptyDescription: selectedTab == "policies"
                ? "No notification policies configured in this account."
                : "No webhook destinations configured in this account."
        )
    }
    
    @ViewBuilder
    private func policyRow(_ p: AlertingPolicy) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(p.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
                Text(p.isEnabled ? "Active" : "Disabled")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(p.isEnabled ? .green : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(p.isEnabled ? Color.green.opacity(0.12) : Color.secondary.opacity(0.12)))
            }
            
            if let desc = p.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if let type = p.alertType {
                Text(type)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
