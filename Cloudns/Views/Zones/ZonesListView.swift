import SwiftUI

// MARK: - ZonesListView

struct ZonesListView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = ZonesViewModel()
    @AppStorage(AppStorageKey.isLoggedIn) private var isLoggedIn = true
    @State private var searchText = ""
    @State private var zoneToDelete: Zone?
    @State private var showingDeleteAlert = false
    @State private var showAddZoneSheet = false
    
    private var displayedZones: [Zone] {
        viewModel.filteredZones(query: searchText)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    skeletonSection
                } else if !displayedZones.isEmpty {
                    zonesSection
                }
            }
            .listStyle(.insetGrouped)
            .centerConstrainedWidth(maxWidth: 840)
            .navigationTitle("My Domains")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: viewModel.totalCount > 0 ? "Search \(viewModel.totalCount) domains" : "Search domains"
            )
            .refreshable {
                await viewModel.fetchZones(isRefresh: true)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.addZoneError = nil
                        showAddZoneSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Domain")
                }
            }
            .sheet(isPresented: $showAddZoneSheet) {
                AddZoneView(viewModel: viewModel, isPresented: $showAddZoneSheet)
            }
            .overlay {
                emptyStateOverlay
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoneDeleted)) { _ in
            Task { await viewModel.fetchZones(isRefresh: true) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoneUpdated)) { _ in
            Task { await viewModel.fetchZones(isRefresh: true) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .accountSwitched)) { _ in
            viewModel.resetState()
            Task { await viewModel.fetchZones(isRefresh: true) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .localCachePurged)) { _ in
            viewModel.resetState()
            Task { await viewModel.fetchZones(isRefresh: true) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .appWillEnterForeground)) { _ in
            if viewModel.isStale {
                Task { await viewModel.fetchZones(isRefresh: true) }
            }
        }
        .task {
            if !viewModel.hasFetchedData || viewModel.isStale {
                await viewModel.fetchZones()
            }
        }
        .confirmationDialog(
            "Remove Zone",
            isPresented: $showingDeleteAlert,
            titleVisibility: .visible,
            presenting: zoneToDelete
        ) { zone in
            Button("Remove \(zone.name)", role: .destructive) {
                Task {
                    await viewModel.deleteZone(zoneId: zone.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { zone in
            Text("Are you sure you want to remove \(zone.name) from your Cloudflare account? This action cannot be undone.")
        }
        .toastContainer()
    }
    
    // MARK: - Subviews
    
    private var skeletonSection: some View {
        Section {
            ForEach(Zone.placeholders) { placeholderZone in
                ZoneRowView(zone: placeholderZone)
                    .redacted(reason: .placeholder)
                    .shimmering()
            }
        }
    }
    
    private var zonesSection: some View {
        Section {
            ForEach(displayedZones) { zone in
                NavigationLink(destination: ZoneDetailView(zone: zone)) {
                    ZoneRowView(zone: zone)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        HapticManager.impact(.medium)
                        zoneToDelete = zone
                        showingDeleteAlert = true
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }

            if viewModel.canLoadMore && searchText.isEmpty && viewModel.hasFetchedData {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .onAppear {
                    Task {
                        await viewModel.fetchZones(isRefresh: false)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateOverlay: some View {
        if viewModel.hasFetchedData {
            if let errorMessage = viewModel.errorMessage, viewModel.zones.isEmpty {
                StateOverlayView(
                    state: .error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task { await viewModel.fetchZones(isRefresh: true) }
                        }
                    )
                )
            } else if viewModel.zones.isEmpty {
                StateOverlayView(
                    state: .empty(
                        icon: "globe",
                        title: "No Domains Found",
                        message: "Add your first domain to start managing DNS records and Cloudflare edge services.",
                        actionTitle: "Add Domain",
                        action: { showAddZoneSheet = true }
                    )
                )
            } else if displayedZones.isEmpty && !searchText.isEmpty {
                StateOverlayView(
                    state: .search(
                        query: searchText,
                        clearAction: { searchText = "" }
                    )
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZonesListView()
}
