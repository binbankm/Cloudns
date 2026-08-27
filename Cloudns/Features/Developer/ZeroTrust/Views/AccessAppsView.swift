import Foundation
import SwiftUI

struct AccessAppsView: View {
    let accountId: String
    @StateObject private var viewModel: AccessAppsViewModel
    @State private var appToDelete: AccessApp?
    @State private var showingDeleteAlert = false
    @State private var showingAddSheet = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: AccessAppsViewModel(accountId: accountId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $viewModel.searchText,
                prompt: "Search Applications"
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(Color(.systemGroupedBackground))
            
            List {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section {
                        ForEach(AccessApp.placeholders) { placeholder in
                            appRow(placeholder)
                        }
                    }
                    .skeletonLoading(true)
                } else if !viewModel.filteredApps.isEmpty {
                    Section(header: Text("Protected Applications (\(viewModel.apps.count))")) {
                        ForEach(viewModel.filteredApps) { app in
                            NavigationLink(destination: AccessAppDetailView(accountId: accountId, app: app)) {
                                appRow(app)
                            }
                            .contentShape(Rectangle())
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = app.domain
                                    HapticManager.notification(.success)
                                    ToastManager.shared.showCopied("Domain copied")
                                } label: {
                                    Label("Copy Domain", systemImage: "doc.on.doc")
                                }
                                
                                Button {
                                    UIPasteboard.general.string = app.name
                                    HapticManager.notification(.success)
                                    ToastManager.shared.showCopied("Name copied")
                                } label: {
                                    Label("Copy App Name", systemImage: "doc.on.doc")
                                }
                                
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    appToDelete = app
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete Application", systemImage: "trash")
                                }
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
            .scrollDismissesKeyboard(.interactively)
            .centerConstrainedWidth(maxWidth: 840)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Access Applications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Access Application")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddAccessAppSheetView(viewModel: viewModel)
        }
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
