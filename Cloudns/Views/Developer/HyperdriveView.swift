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
            CreateHyperdriveSheetView(viewModel: viewModel)
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
