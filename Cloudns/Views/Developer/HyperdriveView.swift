import Foundation
import SwiftUI
import Combine

@MainActor
final class HyperdriveViewModel: ObservableObject {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var configs: [HyperdriveConfig] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var hasFetchedData: Bool = false
    @Published var errorMessage: String? = nil
    
    init(accountId: String) {
        self.accountId = accountId
    }
    
    var filteredConfigs: [HyperdriveConfig] {
        if searchText.isEmpty { return configs }
        return configs.filter { $0.name.localizedCaseInsensitiveContains(searchText) || ($0.origin?.host ?? "").localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchConfigs() async {
        isLoading = true
        errorMessage = nil
        do {
            self.configs = try await apiClient.listHyperdriveConfigs(accountId: accountId)
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
            self.hasFetchedData = true
        }
        isLoading = false
    }
    
    func createConfig(payload: HyperdriveCreate) async -> Bool {
        do {
            _ = try await apiClient.createHyperdriveConfig(accountId: accountId, payload: payload)
            ToastManager.shared.showSuccess("Hyperdrive Created", message: payload.name)
            await fetchConfigs()
            return true
        } catch {
            ToastManager.shared.showError("Create Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deleteConfig(id: String) async {
        do {
            try await apiClient.deleteHyperdriveConfig(accountId: accountId, configId: id)
            ToastManager.shared.showSuccess("Hyperdrive Deleted", message: "")
            await fetchConfigs()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
}

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
            if viewModel.isLoading && !viewModel.hasFetchedData {
                Section {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else if let err = viewModel.errorMessage, !viewModel.hasFetchedData {
                Section {
                    EmptyStateView.error(message: LocalizedStringKey(err)) {
                        Task { await viewModel.fetchConfigs() }
                    }
                }
                .listRowBackground(Color.clear)
            } else if viewModel.configs.isEmpty {
                Section {
                    EmptyStateView(
                        icon: "bolt.horizontal.fill",
                        title: "No Hyperdrive Configs",
                        message: "Hyperdrive accelerates database queries from Workers to existing regional databases.",
                        actionTitle: "Create Config",
                        action: { showingCreateSheet = true }
                    )
                }
                .listRowBackground(Color.clear)
            } else if viewModel.filteredConfigs.isEmpty {
                Section {
                    EmptyStateView.search(query: viewModel.searchText) {
                        viewModel.searchText = ""
                    }
                }
                .listRowBackground(Color.clear)
            } else {
                Section(header: Text("Database Accelerators (\(viewModel.configs.count))")) {
                    ForEach(viewModel.filteredConfigs) { config in
                        NavigationLink(destination: HyperdriveDetailView(accountId: accountId, config: config, viewModel: viewModel)) {
                            HStack(spacing: 12) {
                                Image(systemName: "bolt.horizontal.fill")
                                    .foregroundStyle(.green)
                                    .font(.title3)
                                    .frame(width: 32, height: 32)
                                    .background(Color.green.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(config.name)
                                        .font(.body.weight(.medium))
                                    
                                    if let host = config.origin?.host {
                                        Text(host)
                                            .font(.caption2.monospaced())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if let scheme = config.origin?.scheme {
                                    Text(scheme.uppercased())
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.green)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
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
        .alert("Delete Hyperdrive", isPresented: $showingDeleteAlert, presenting: configToDelete) { cfg in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteConfig(id: cfg.id) }
            }
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
        .toastContainer()
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
                }
                
                Section(header: Text("Origin Connection")) {
                    Picker("Engine", selection: $scheme) {
                        Text("PostgreSQL").tag("postgres")
                    }
                    
                    TextField("Host (e.g. db.example.com)", text: $host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                    
                    TextField("Database Name", text: $database)
                    TextField("User", text: $user)
                    SecureField("Password", text: $password)
                }
            }
            .navigationTitle("New Hyperdrive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
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
        }
    }
}
