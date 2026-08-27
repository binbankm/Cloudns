import SwiftUI

struct LoadBalancerView: View {
    let zoneId: String
    
    @StateObject private var viewModel: LoadBalancerViewModel
    @State private var selectedTab = 0
    @State private var showingAddSheet = false
    @State private var searchText = ""
    
    init(zoneId: String) {
        self.zoneId = zoneId
        _viewModel = StateObject(wrappedValue: LoadBalancerViewModel(zoneId: zoneId))
    }
    
    private var displayedLoadBalancers: [LoadBalancer] {
        if searchText.isEmpty { return viewModel.loadBalancers }
        return viewModel.loadBalancers.filter { ($0.name ?? "").localizedStandardContains(searchText) }
    }
    
    private var displayedPools: [LBPool] {
        if searchText.isEmpty { return viewModel.pools }
        return viewModel.pools.filter {
            ($0.name ?? "").localizedStandardContains(searchText) ||
            ($0.description ?? "").localizedStandardContains(searchText)
        }
    }
    
    private var displayedMonitors: [LBMonitor] {
        if searchText.isEmpty { return viewModel.monitors }
        return viewModel.monitors.filter {
            ($0.description ?? "").localizedStandardContains(searchText) ||
            ($0.path ?? "").localizedStandardContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $searchText,
                prompt: "Search Load Balancers, Pools, Monitors"
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(Color(.systemGroupedBackground))
            
            Picker("Section", selection: $selectedTab) {
                Text("Load Balancers").tag(0)
                Text("Pools").tag(1)
                Text("Monitors").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            
            contentList
                .centerConstrainedWidth(maxWidth: 840)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Load Balancing")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchData()
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchData()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showingAddSheet = true
                }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Load Balancing Resource")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            if selectedTab == 0 {
                AddLoadBalancerView(zoneId: zoneId, viewModel: viewModel)
            } else if selectedTab == 1 {
                AddLBPoolSheetView(viewModel: viewModel)
            } else {
                AddLBMonitorSheetView(viewModel: viewModel)
            }
        }
    }
    
    @ViewBuilder
    private var contentList: some View {
        List {
            if selectedTab == 0 {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section {
                        ForEach(LoadBalancer.placeholders) { placeholderLB in
                            lbRow(placeholderLB)
                        }
                    }
                    .skeletonLoading(true)
                } else if !displayedLoadBalancers.isEmpty {
                    Section(header: Text("Load Balancers (\(displayedLoadBalancers.count))")) {
                        ForEach(displayedLoadBalancers) { lb in
                            lbRow(lb)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        HapticManager.impact(.medium)
                                        Task {
                                            await viewModel.deleteLoadBalancer(id: lb.id)
                                            CloudnsToastManager.shared.showSuccess("Load Balancer Deleted", message: lb.name ?? "")
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            } else if selectedTab == 1 {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section {
                        ForEach(LBPool.placeholders) { placeholderPool in
                            poolRow(placeholderPool)
                        }
                    }
                    .skeletonLoading(true)
                } else if !displayedPools.isEmpty {
                    Section(header: Text("Origin Pools (\(displayedPools.count))")) {
                        ForEach(displayedPools) { pool in
                            poolRow(pool)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        HapticManager.impact(.medium)
                                        Task {
                                            await viewModel.deletePool(poolId: pool.id)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            } else if selectedTab == 2 {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section {
                        ForEach(LBMonitor.placeholders) { placeholderMon in
                            monRow(placeholderMon)
                        }
                    }
                    .skeletonLoading(true)
                } else if !displayedMonitors.isEmpty {
                    Section(header: Text("Monitors (\(displayedMonitors.count))")) {
                        ForEach(displayedMonitors) { monitor in
                            monRow(monitor)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        HapticManager.impact(.medium)
                                        Task {
                                            await viewModel.deleteMonitor(monitorId: monitor.id)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.loadBalancers.isEmpty && viewModel.pools.isEmpty && viewModel.monitors.isEmpty {
                    CloudnsStateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchData() } }
                        )
                    )
                } else if selectedTab == 0 && viewModel.loadBalancers.isEmpty {
                    CloudnsStateOverlayView(
                        state: .empty(
                            icon: "arrow.triangle.branch",
                            title: "No Load Balancers",
                            message: "Distribute incoming traffic across server pools for high availability.",
                            actionTitle: "Add Load Balancer",
                            action: { showingAddSheet = true }
                        )
                    )
                } else if selectedTab == 1 && viewModel.pools.isEmpty {
                    CloudnsStateOverlayView(
                        state: .empty(
                            icon: "server.rack",
                            title: "No Origin Pools",
                            message: "Group multiple origin servers together with health monitoring.",
                            actionTitle: "Add Pool",
                            action: { showingAddSheet = true }
                        )
                    )
                } else if selectedTab == 2 && viewModel.monitors.isEmpty {
                    CloudnsStateOverlayView(
                        state: .empty(
                            icon: "waveform.path.ecg",
                            title: "No Health Monitors",
                            message: "Send automated HTTP/HTTPS health checks to your origin servers.",
                            actionTitle: "Add Monitor",
                            action: { showingAddSheet = true }
                        )
                    )
                } else if !searchText.isEmpty && ((selectedTab == 0 && displayedLoadBalancers.isEmpty) || (selectedTab == 1 && displayedPools.isEmpty) || (selectedTab == 2 && displayedMonitors.isEmpty)) {
                    CloudnsStateOverlayView(
                        state: .search(
                            query: searchText,
                            clearAction: { searchText = "" }
                        )
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func lbRow(_ lb: LoadBalancer) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(lb.name ?? lb.id)
                    .font(.body)
                    .foregroundStyle(.primary)
                Spacer()
                CloudnsBadge(lb.enabled == true ? .active("Active") : .custom(color: .secondary, text: "Inactive"), isCompact: true)
            }
            if let fallback = lb.fallbackPool {
                Text("Fallback: \(fallback)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func poolRow(_ pool: LBPool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(pool.name ?? pool.id)
                    .font(.body)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(pool.origins?.count ?? 0) Origins")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let desc = pool.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let origins = pool.origins, !origins.isEmpty {
                HStack(spacing: 6) {
                    ForEach(origins.prefix(3), id: \.idResolved) { o in
                        Text(o.name ?? o.address ?? "")
                            .font(.caption2.monospaced())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.secondarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func monRow(_ monitor: LBMonitor) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(monitor.description ?? monitor.id)
                    .font(.body)
                    .foregroundStyle(.primary)
                Spacer()
                CloudnsBadge(.custom(color: .blue, text: monitor.type?.uppercased() ?? "HTTP"), isCompact: true)
            }
            HStack {
                Text(monitor.method ?? "GET")
                    .font(.caption)
                Text(monitor.path ?? "/")
                    .font(.caption.monospaced())
                Spacer()
                if let codes = monitor.expectedCodes {
                    Text("Expect: \(codes)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
