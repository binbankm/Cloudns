import Foundation
import SwiftUI
import Combine

@MainActor
final class AlertingViewModel: ObservableObject {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var availableTypes: [AlertingAvailableType] = []
    @Published var policies: [AlertingPolicy] = []
    @Published var webhooks: [AlertingWebhookDestination] = []
    
    @Published var isLoading: Bool = false
    @Published var hasFetchedData: Bool = false
    @Published var errorMessage: String? = nil
    
    init(accountId: String) {
        self.accountId = accountId
    }
    
    func fetchData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchTypes = apiClient.listAvailableAlertTypes(accountId: accountId)
            async let fetchPol = apiClient.listAlertingPolicies(accountId: accountId)
            async let fetchHooks = apiClient.listAlertingWebhooks(accountId: accountId)
            
            let (types, pols, hooks) = try await (fetchTypes, fetchPol, fetchHooks)
            self.availableTypes = types
            self.policies = pols
            self.webhooks = hooks
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
            self.hasFetchedData = true
        }
        isLoading = false
    }
    
    func deletePolicy(id: String) async {
        do {
            try await apiClient.deleteAlertingPolicy(accountId: accountId, policyId: id)
            ToastManager.shared.showSuccess("Policy Deleted", message: "")
            await fetchData()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}

struct AlertingView: View {
    let accountId: String
    @StateObject private var viewModel: AlertingViewModel
    @State private var selectedTab = "policies"
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: AlertingViewModel(accountId: accountId))
    }
    
    var body: some View {
        List {
            if viewModel.isLoading && !viewModel.hasFetchedData {
                Section {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else if let err = viewModel.errorMessage, !viewModel.hasFetchedData {
                Section {
                    EmptyStateView.error(message: LocalizedStringKey(err)) {
                        Task { await viewModel.fetchData() }
                    }
                }
                .listRowBackground(Color.clear)
            } else {
                Picker("Category", selection: $selectedTab) {
                    Text("Active Policies").tag("policies")
                    Text("Available Alerts").tag("available")
                    Text("Webhooks").tag("webhooks")
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .padding(.vertical, 4)
                    
                    if selectedTab == "policies" {
                        if viewModel.policies.isEmpty {
                            Section {
                                Text("No notification policies configured.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Section(header: Text("Configured Policies (\(viewModel.policies.count))")) {
                                ForEach(viewModel.policies) { p in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(p.name)
                                                .font(.body.weight(.medium))
                                            Spacer()
                                            Text(p.enabled ? "Active" : "Disabled")
                                                .font(.caption2.weight(.bold))
                                                .foregroundStyle(p.enabled ? .green : .secondary)
                                        }
                                        
                                        if let desc = p.description, !desc.isEmpty {
                                            Text(desc)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        if let type = p.alertType {
                                            Text(type)
                                                .font(.caption2.monospaced())
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            Task { await viewModel.deletePolicy(id: p.id) }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
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
                        Section(header: Text("Destinations & Webhooks (\(viewModel.webhooks.count))")) {
                            if viewModel.webhooks.isEmpty {
                                Text("No webhook destinations configured in this account.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(viewModel.webhooks) { h in
                                    HStack {
                                        Image(systemName: "bell.badge.fill")
                                            .foregroundStyle(.orange)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(h.name)
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
        }
        .listStyle(.insetGrouped)
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
        .toastContainer()
    }
}
