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
                Section(header: Text("Database Accelerators (\(viewModel.configs.count))")) {
                    ForEach(viewModel.configs) { config in
                        NavigationLink(destination: HyperdriveDetailView(accountId: accountId, config: config, viewModel: viewModel)) {
                            configRow(config)
                        }
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = config.name
                                ToastManager.shared.showCopied("Config Name Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy Name", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                UIPasteboard.general.string = config.id
                                ToastManager.shared.showCopied("Config ID Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy Config ID", systemImage: "link")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                configToDelete = config
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete Accelerator", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                configToDelete = config
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(HIGColors.error)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
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
                .higTouchTarget(44)
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateHyperdriveSheetView(viewModel: viewModel)
                .higToast()
        }
        .confirmationDialog("Delete Hyperdrive", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: configToDelete) { cfg in
            Button("Delete '\(cfg.name)'", role: .destructive) {
                Task {
                    await viewModel.deleteConfig(id: cfg.id)
                    ToastManager.shared.showSuccess("Hyperdrive Accelerator Deleted", icon: "trash.fill")
                    HIGFeedback.success()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { cfg in
            Text("Are you sure you want to delete '\(cfg.name)'? Worker bindings connected to this accelerator will stop functioning.")
        }
        .refreshable {
            await viewModel.fetchConfigs()
        }
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Hyperdrive Configs…"))
            } else if viewModel.hasFetchedData {
                if let err = viewModel.errorMessage, viewModel.configs.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(err),
                            retryAction: { Task { await viewModel.fetchConfigs() } }
                        )
                    )
                } else if viewModel.configs.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Hyperdrive Configs",
                            systemImage: "bolt.horizontal.fill",
                            description: "Hyperdrive accelerates database queries from Workers to existing regional databases.",
                            actionTitle: "Create Config",
                            action: { showingCreateSheet = true }
                        )
                    )
                }
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchConfigs()
            }
        }
    }
    
    @ViewBuilder
    private func configRow(_ config: HyperdriveConfig) -> some View {
        HStack(alignment: .center, spacing: HIGTokens.Spacing.md) {
            ListRowIcon(icon: "bolt.horizontal.fill", color: HIGColors.success)
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text(config.name)
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let origin = config.origin, let host = origin.host {
                    let dbName = origin.database ?? ""
                    let dbScheme = origin.scheme ?? "postgres"
                    let dbPort = origin.port ?? 5432
                    Text(verbatim: "\(dbScheme)://\(host):\(dbPort)/\(dbName)")
                        .font(HIGTypography.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            HIGBadge(.custom(color: HIGColors.success, text: (config.origin?.scheme ?? "postgres").uppercased()), isCompact: true)
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
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
                Section(header: Text("Configuration Name")) {
                    TextField("my-postgres-hyperdrive", text: $name)
                        .font(HIGTypography.body)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Origin Database")) {
                    TextField("Host (e.g. db.example.com)", text: $host)
                        .font(HIGTypography.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Port", text: $port)
                        .font(HIGTypography.body.monospacedDigit())
                        .keyboardType(.numberPad)
                    
                    TextField("Database Name", text: $database)
                        .font(HIGTypography.body.monospaced())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("User", text: $user)
                        .font(HIGTypography.body)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .font(HIGTypography.body)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Hyperdrive")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .higTouchTarget(44)
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
                                HIGFeedback.success()
                                dismiss()
                            } else {
                                ToastManager.shared.showError("Failed to Create Hyperdrive")
                                HIGFeedback.error()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || host.trimmingCharacters(in: .whitespaces).isEmpty || database.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                    .higTouchTarget(44)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
