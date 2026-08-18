import Foundation
import SwiftUI

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
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section(header: Text("Database Accelerators")) {
                    ForEach(HyperdriveConfig.placeholders) { placeholder in
                        configRow(placeholder)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
            } else if !viewModel.filteredConfigs.isEmpty {
                Section(header: Text("Database Accelerators (\(viewModel.configs.count))")) {
                    ForEach(viewModel.filteredConfigs) { config in
                        NavigationLink(destination: HyperdriveDetailView(accountId: accountId, config: config, viewModel: viewModel)) {
                            configRow(config)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                configToDelete = config
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
        .navigationTitle("Hyperdrive")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Hyperdrive")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateHyperdriveSheet(viewModel: viewModel)
        }
        .confirmationDialog("Delete Hyperdrive", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: configToDelete) { cfg in
            Button("Delete '\(cfg.name)'", role: .destructive) {
                Task { await viewModel.deleteConfig(id: cfg.id) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { cfg in
            Text("Are you sure you want to delete '\(cfg.name)'? Worker bindings connected to this accelerator will stop functioning.")
        }
        .refreshable {
            await viewModel.fetchConfigs()
        }
        .overlay {
            if viewModel.hasFetchedData {
                if let err = viewModel.errorMessage, viewModel.configs.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(err),
                            retryAction: { Task { await viewModel.fetchConfigs() } }
                        )
                    )
                } else if viewModel.configs.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "bolt.horizontal.fill",
                            title: "No Hyperdrive Configs",
                            message: "Hyperdrive accelerates database queries from Workers to existing regional databases.",
                            actionTitle: "Create Config",
                            action: { showingCreateSheet = true }
                        )
                    )
                } else if viewModel.filteredConfigs.isEmpty && !viewModel.searchText.isEmpty {
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
                await viewModel.fetchConfigs()
            }
        }
    }
    
    @ViewBuilder
    private func configRow(_ config: HyperdriveConfig) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.horizontal.fill")
                .foregroundStyle(.green)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(config.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let host = config.origin?.host {
                    Text(host)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct HyperdriveDetailView: View {
    let accountId: String
    let config: HyperdriveConfig
    @ObservedObject var viewModel: HyperdriveViewModel
    
    var body: some View {
        List {
            Section(header: Text("Accelerator Overview")) {
                HStack {
                    Text("Config Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(config.name)
                        .font(.body.weight(.medium))
                }
                
                HStack {
                    Text("Config ID")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(config.id)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            
            if let origin = config.origin {
                Section(header: Text("Origin Database")) {
                    HStack {
                        Text("Scheme")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(origin.scheme?.uppercased() ?? "POSTGRES")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Text("Host")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(origin.host ?? "")
                            .font(.caption.monospaced())
                    }
                    
                    HStack {
                        Text("Port")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(origin.port ?? 5432)")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Text("Database Name")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(origin.database ?? "")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Text("User")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(origin.user ?? "")
                            .font(.subheadline)
                    }
                }
            }
            
            if let caching = config.caching {
                Section(header: Text("Query Caching")) {
                    HStack {
                        Text("Cache Status")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(caching.disabled == true ? "Disabled" : "Enabled")
                            .font(.subheadline)
                            .foregroundStyle(caching.disabled == true ? Color.secondary : Color.green)
                    }
                    
                    if let maxAge = caching.maxAge {
                        HStack {
                            Text("Max Age")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(maxAge)s")
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(config.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CreateHyperdriveSheet: View {
    @ObservedObject var viewModel: HyperdriveViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var host = ""
    @State private var port = "5432"
    @State private var database = "postgres"
    @State private var user = "postgres"
    @State private var password = ""
    @State private var scheme = "postgres"
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Configuration Name")) {
                    TextField("my-database-accelerator", text: $name)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                }
                
                Section(header: Text("Origin Connection")) {
                    Picker("Engine", selection: $scheme) {
                        Text("PostgreSQL").tag("postgres")
                    }
                    
                    TextField("Host (e.g. db.example.com)", text: $host)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                        .keyboardType(.numberPad)
                    
                    TextField("Database Name", text: $database)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    TextField("User", text: $user)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Hyperdrive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isSubmitting = true
                            let p = Int(port) ?? 5432
                            let origin = HyperdriveOriginInput(host: host, port: p, database: database, user: user, password: password, scheme: scheme)
                            let payload = HyperdriveCreate(name: name, origin: origin)
                            let success = await viewModel.createConfig(payload: payload)
                            if success { dismiss() }
                            isSubmitting = false
                        }
                    }
                    .disabled(name.isEmpty || host.isEmpty || password.isEmpty || isSubmitting)
                }
            }
            .interactiveDismissDisabled(isSubmitting)
            .toastContainer()
        }
    }
}
