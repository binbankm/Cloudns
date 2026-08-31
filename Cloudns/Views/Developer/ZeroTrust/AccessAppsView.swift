import Foundation
import SwiftUI

// MARK: - AccessAppsView

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
                Section(header: Text("Protected Applications (\(viewModel.apps.count))")) {
                    ForEach(viewModel.filteredApps) { app in
                        NavigationLink(destination: AccessAppDetailView(accountId: accountId, app: app)) {
                            appRow(app)
                        }
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = app.domain
                                ToastManager.shared.showCopied()
                            } label: {
                                Label("Copy Domain", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                UIPasteboard.general.string = app.name
                                ToastManager.shared.showCopied()
                            } label: {
                                Label("Copy App Name", systemImage: "doc.on.doc")
                            }
                            
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                appToDelete = app
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete Application", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
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
             .higToast()
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
            if !viewModel.hasFetchedData && viewModel.isLoading {
            HIGContentState(.loading(message: "Loading Access Applications…"))
        } else if viewModel.hasFetchedData {
                if let err = viewModel.errorMessage, viewModel.apps.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(err),
                            retryAction: { Task { await viewModel.fetchApps() } }
                        )
                    )
                } else if viewModel.apps.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Access Applications",
                            systemImage: "lock.shield.fill",
                            description: "Zero Trust Access secures self-hosted and SaaS applications with identity-driven policies.",
                            actionTitle: "Add Application",
                            action: { showingAddSheet = true }
                        )
                    )
                } else if viewModel.filteredApps.isEmpty && !viewModel.searchText.isEmpty {
                    HIGContentState(.search(query: viewModel.searchText))
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
            ListRowIcon(icon: "lock.shield.fill", color: .blue, size: 32, cornerRadius: 8)
            
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
                HIGBadge(.custom(color: .purple, text: type.capitalized), isCompact: true)
            }
        }
        .padding(.vertical, 3)
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
                Section(header: Text("Application Info")) {
                    TextField("App Name (e.g. Jira Internal)", text: $name)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)
                    
                    TextField("Domain (e.g. jira.example.com)", text: $domain)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                
                Section(header: Text("Session Settings")) {
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
                                HIGFeedback.success()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
                            }
                            isCreating = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || domain.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }
}
