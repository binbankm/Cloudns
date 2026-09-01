import Foundation
import SwiftUI

// MARK: - HyperdriveView

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
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
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
        .navigationTitle("Hyperdrive")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
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
        HStack(alignment: .center, spacing: 14) {
            ListRowIcon(icon: "bolt.horizontal.fill", color: .green, size: 32, cornerRadius: 8)
            
            VStack(alignment: .leading, spacing: 3) {
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
            
            HIGBadge(.custom(color: .green, text: (config.origin?.scheme ?? "postgres").uppercased()), isCompact: true)
        }
        .padding(.vertical, 3)
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
                }
                
                Section(header: Text("Origin Database")) {
                    TextField("Host (e.g. db.example.com)", text: $host)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                    
                    TextField("Database Name", text: $database)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("User", text: $user)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
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
                                HIGFeedback.success()
                                dismiss()
                            } else {
                                HIGFeedback.error()
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
