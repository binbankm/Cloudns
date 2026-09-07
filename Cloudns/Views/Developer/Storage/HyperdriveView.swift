import Foundation
import SwiftUI

// MARK: - HyperdriveView
// Apple HIG Compliant Cloudflare Hyperdrive Regional Database Accelerators

struct HyperdriveView: View {
    let accountId: String
    @StateObject private var viewModel: HyperdriveViewModel
    @State private var showingCreateSheet = false
    @State private var configToDelete: HyperdriveConfig?
    @State private var showingDeleteAlert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: HyperdriveViewModel(accountId: accountId))
    }
    
    var body: some View {
        List {
            if !viewModel.configs.isEmpty {
                Section("Database Accelerators (\(viewModel.configs.count))") {
                    ForEach(viewModel.configs) { config in
                        NavigationLink(destination: HyperdriveDetailView(accountId: accountId, config: config, viewModel: viewModel)) {
                            configRow(config)
                        }
                        .contextMenu {
                            Button {
                                copyToClipboard(config.name, toast: "Config Name Copied")
                            } label: {
                                Label("Copy Name", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                copyToClipboard(config.id, toast: "Config ID Copied")
                            } label: {
                                Label("Copy Config ID", systemImage: "link")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                configToDelete = config
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete Accelerator", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                configToDelete = config
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
            loadingMessage: "Loading Hyperdrive Configs…",
            isEmpty: viewModel.hasFetchedData && viewModel.configs.isEmpty && viewModel.errorMessage == nil,
            emptyTitle: "No Hyperdrive Configs",
            emptySystemImage: "bolt.horizontal.fill",
            emptyDescription: "Hyperdrive accelerates database queries from Workers to existing regional databases.",
            emptyActionTitle: "Create Config",
            emptyAction: { showingCreateSheet = true },
            errorMessage: viewModel.errorMessage.map { LocalizedStringKey($0) },
            retryAction: { Task { await viewModel.fetchConfigs() } }
        )
        .navigationTitle("Hyperdrive")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create Accelerator")
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateHyperdriveSheetView(viewModel: viewModel)
        }
        .confirmationDialog("Delete Hyperdrive", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: configToDelete) { cfg in
            Button("Delete '\(cfg.name)'", role: .destructive) {
                Task {
                    await viewModel.deleteConfig(id: cfg.id)
                    ToastManager.shared.showSuccess("Hyperdrive Accelerator Deleted", icon: "trash.fill")
                    HapticManager.notification(.success)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { cfg in
            Text("Are you sure you want to delete '\(cfg.name)'? Worker bindings connected to this accelerator will stop functioning.")
        }
        .refreshable {
            await viewModel.fetchConfigs()
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchConfigs()
            }
        }
    }
    
    @ViewBuilder
    private func configRow(_ config: HyperdriveConfig) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ListRowIcon(icon: "bolt.horizontal.fill", color: .green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(config.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let origin = config.origin, let host = origin.host {
                    let dbName = origin.database ?? ""
                    let dbScheme = origin.scheme ?? "postgres"
                    let dbPort = origin.port ?? 5432
                    Text(verbatim: "\(dbScheme)://\(host):\(dbPort)/\(dbName)")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            let schemeName = (config.origin?.scheme ?? "postgres").uppercased()
            Text(schemeName)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.green)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.green.opacity(0.12)))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - CreateHyperdriveSheetView (Inlined & Cohesive)

struct CreateHyperdriveSheetView: View {
    @ObservedObject var viewModel: HyperdriveViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var host = ""
    @State private var port = "5432"
    @State private var database = ""
    @State private var user = ""
    @State private var password = ""
    @State private var scheme = "postgres"
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Configuration Name") {
                    TextField("my-postgres-hyperdrive", text: $name)
                        .font(.body)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section("Origin Database") {
                    TextField("Host (e.g. db.example.com)", text: $host)
                        .font(.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Port", text: $port)
                        .font(.body.monospacedDigit())
                        .keyboardType(.numberPad)
                    
                    TextField("Database Name", text: $database)
                        .font(.body.monospaced())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("User", text: $user)
                        .font(.body)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .font(.body)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Hyperdrive")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isSaving = true
                            let input = HyperdriveOriginInput(
                                host: host.trimmingCharacters(in: .whitespaces),
                                port: Int(port) ?? 5432,
                                database: database.trimmingCharacters(in: .whitespaces),
                                user: user.trimmingCharacters(in: .whitespaces),
                                password: password,
                                scheme: scheme
                            )
                            let payload = HyperdriveCreate(name: name.trimmingCharacters(in: .whitespaces), origin: input)
                            let ok = await viewModel.createConfig(payload: payload)
                            if ok {
                                ToastManager.shared.showSuccess("Hyperdrive Created", icon: "bolt.horizontal.fill")
                                HapticManager.notification(.success)
                                dismiss()
                            } else {
                                ToastManager.shared.showError("Failed to Create Hyperdrive")
                                HapticManager.notification(.error)
                            }
                            isSaving = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || host.trimmingCharacters(in: .whitespaces).isEmpty || database.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
