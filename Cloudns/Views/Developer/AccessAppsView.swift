import Foundation
import SwiftUI

struct AccessAppsView: View {
    let accountId: String
    @StateObject private var viewModel: AccessAppsViewModel
    @State private var appToDelete: AccessApp?
    @State private var showingDeleteAlert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: AccessAppsViewModel(accountId: accountId))
    }
    
    var body: some View {
        List {
            if !viewModel.filteredApps.isEmpty {
                Section(header: Text("Protected Applications (\(viewModel.apps.count))")) {
                    ForEach(viewModel.filteredApps) { app in
                        NavigationLink(destination: AccessAppDetailView(accountId: accountId, app: app)) {
                            appRow(app)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                appToDelete = app
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("Access Applications")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Applications")
        .confirmationDialog("Delete Application", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: appToDelete) { app in
            Button("Delete '\(app.name)'", role: .destructive) {
                Task { await viewModel.deleteApp(id: app.id) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { app in
            Text("Are you sure you want to delete '\(app.name)'? Traffic to \(app.domain) will no longer be protected by Zero Trust.")
        }
        .refreshable {
            await viewModel.fetchApps()
        }
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.hasFetchedData {
                if let err = viewModel.errorMessage, viewModel.apps.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(err),
                            retryAction: { Task { await viewModel.fetchApps() } }
                        )
                    )
                } else if viewModel.apps.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "lock.shield.fill",
                            title: "No Access Applications",
                            message: "Zero Trust Access secures self-hosted and SaaS applications with identity-driven policies.",
                            actionTitle: "Refresh",
                            action: { Task { await viewModel.fetchApps() } }
                        )
                    )
                } else if viewModel.filteredApps.isEmpty && !viewModel.searchText.isEmpty {
                    StateOverlayView(
                        state: .search(
                            query: viewModel.searchText,
                            clearAction: { viewModel.searchText = "" }
                        )
                    )
                }
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchApps()
            }
        }
    }
    
    @ViewBuilder
    private func appRow(_ app: AccessApp) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.purple)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(Color.purple.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text(app.domain)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct AccessAppDetailView: View {
    let accountId: String
    let app: AccessApp
    @State private var policies: [AccessPolicy] = []
    @State private var isLoadingPolicies = false
    @State private var errorMessage: String?
    
    var body: some View {
        List {
            Section(header: Text("Application Details")) {
                HStack {
                    Text("Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(app.name)
                        .font(.body.weight(.medium))
                }
                
                HStack {
                    Text("Domain")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(app.domain)
                        .font(.caption.monospaced())
                }
                
                if let aud = app.aud {
                    HStack {
                        Text("Audience Tag (AUD)")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(aud)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section(header: Text("Access Policies (\(policies.count))")) {
                if isLoadingPolicies && policies.isEmpty {
                    ProgressView()
                } else if let err = errorMessage, policies.isEmpty {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if policies.isEmpty {
                    Text("No policies assigned to this application.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(policies) { p in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.name)
                                    .font(.body)
                                Text("Decision: \(p.decision.capitalized)")
                                    .font(.caption2)
                                    .foregroundStyle(p.decision.lowercased() == "allow" ? .green : .orange)
                            }
                            Spacer()
                            if let prec = p.precedence {
                                Text("#\(prec)")
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(app.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchPolicies()
        }
    }
    
    private func fetchPolicies() async {
        isLoadingPolicies = true
        errorMessage = nil
        do {
            var targetId = self.accountId
            if targetId.isEmpty {
                let accounts = try? await CloudflareAPIClient.shared.getAccounts()
                let activeEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
                targetId = accounts?.first(where: { $0.name == activeEmail || $0.id == activeEmail })?.id ?? accounts?.first?.id ?? ""
            }
            guard !targetId.isEmpty else {
                self.policies = []
                self.isLoadingPolicies = false
                return
            }
            self.policies = try await CloudflareAPIClient.shared.listAccessPolicies(accountId: targetId, appId: app.id)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoadingPolicies = false
    }
}
