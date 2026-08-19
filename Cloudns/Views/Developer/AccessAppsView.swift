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
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section(header: Text("Protected Applications")) {
                    ForEach(AccessApp.placeholders) { placeholder in
                        appRow(placeholder)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
            } else if !viewModel.filteredApps.isEmpty {
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
            if viewModel.hasFetchedData {
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
            
            if let type = app.type {
                CloudnsBadge(.custom(color: .purple, text: type.capitalized), isCompact: true)
            }
        }
        .padding(.vertical, 3)
    }
}
