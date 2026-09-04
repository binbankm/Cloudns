import Foundation
import SwiftUI

// MARK: - AccessAppsView
// Apple HIG Compliant Cloudflare Zero Trust Access Protected Applications

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
        List {
            if !viewModel.filteredApps.isEmpty {
                Section("Protected Applications (\(viewModel.apps.count))") {
                    ForEach(viewModel.filteredApps) { app in
                        NavigationLink(destination: AccessAppDetailView(accountId: accountId, app: app)) {
                            appRow(app)
                        }
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button {
                                copyToClipboard(app.domain, toast: "Domain Copied")
                            } label: {
                                Label("Copy Domain", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                copyToClipboard(app.name, toast: "App Name Copied")
                            } label: {
                                Label("Copy App Name", systemImage: "tag")
                            }
                            
                            Divider()
                            
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
                            .tint(.red)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Access Applications…",
            isEmpty: viewModel.hasFetchedData && viewModel.apps.isEmpty && viewModel.errorMessage == nil,
            emptyTitle: "No Access Applications",
            emptyDescription: "Zero Trust Access secures self-hosted and SaaS applications with identity-driven policies.",
            emptyActionTitle: "Add Application",
            emptyAction: { showingAddSheet = true },
            isSearchEmpty: viewModel.hasFetchedData && !viewModel.apps.isEmpty && viewModel.filteredApps.isEmpty && !viewModel.searchText.isEmpty,
            searchQuery: viewModel.searchText,
            errorMessage: viewModel.errorMessage.map { LocalizedStringKey($0) },
            retryAction: { Task { await viewModel.fetchApps() } }
        )
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Applications"
        )
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
                Task {
                    await viewModel.deleteApp(id: app.id)
                    ToastManager.shared.showSuccess("Application Deleted", icon: "trash.fill")
                    HapticManager.notification(.success)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { app in
            Text("Are you sure you want to delete '\(app.name)'? Traffic to \(app.domain) will no longer be protected by Zero Trust.")
        }
        .refreshable {
            await viewModel.fetchApps()
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
            ListRowIcon(icon: "lock.shield.fill", color: .blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text(app.domain)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let type = app.type {
                Text(type.capitalized)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.purple.opacity(0.12)))
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - AddAccessAppSheetView (Inlined & Cohesive)

struct AddAccessAppSheetView: View {
    @ObservedObject var viewModel: AccessAppsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var domain = ""
    @State private var sessionDuration = "24h"
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    let durationOptions = [
        ("15 Minutes", "15m"),
        ("1 Hour", "1h"),
        ("24 Hours", "24h"),
        ("7 Days", "168h"),
        ("1 Month", "720h")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Application Info") {
                    TextField("App Name (e.g. Jira Internal)", text: $name)
                        .font(.body)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)
                    
                    TextField("Domain (e.g. jira.example.com)", text: $domain)
                        .font(.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                
                Section("Session Settings") {
                    Picker("Session Duration", selection: $sessionDuration) {
                        ForEach(durationOptions, id: \.1) { label, value in
                            Text(verbatim: label).tag(value)
                        }
                    }
                }
                
                if let err = errorMessage {
                    Section {
                        Text(verbatim: err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Access App")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            errorMessage = nil
                            do {
                                try await viewModel.createApp(
                                    name: name.trimmingCharacters(in: .whitespaces),
                                    domain: domain.trimmingCharacters(in: .whitespaces),
                                    sessionDuration: sessionDuration
                                )
                                HapticManager.notification(.success)
                                ToastManager.shared.showSuccess("Access App Created", icon: "lock.shield.fill")
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.notification(.error)
                            }
                            isCreating = false
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || domain.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }
}
