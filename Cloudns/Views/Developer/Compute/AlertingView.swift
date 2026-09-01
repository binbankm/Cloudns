import Foundation
import SwiftUI

struct AlertingView: View {
    let accountId: String
    @StateObject private var viewModel: AlertingViewModel
    @State private var selectedTab = "policies"
    
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
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            
            contentList
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Notification Alerts")
        .navigationBarTitleDisplayMode(.inline)
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
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        HIGFeedback.impact(.medium)
                                        Task { await viewModel.deletePolicy(id: p.id) }
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
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundStyle(.orange)
                                    .accessibilityHidden(true)
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
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(p.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
                HIGBadge(p.isEnabled ? .active("Active") : .custom(color: .secondary, text: "Disabled"), isCompact: true)
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
