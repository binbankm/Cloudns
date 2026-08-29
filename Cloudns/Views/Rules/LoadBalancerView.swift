import SwiftUI

// MARK: - LoadBalancerView

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
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search Load Balancers, Pools, Monitors"
        )
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
                    .redacted(reason: .placeholder)
                } else if !displayedLoadBalancers.isEmpty {
                    Section(header: Text("Load Balancers (\(displayedLoadBalancers.count))")) {
                        ForEach(displayedLoadBalancers) { lb in
                            lbRow(lb)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        HIGFeedback.impact(.medium)
                                        Task {
                                            await viewModel.deleteLoadBalancer(id: lb.id)
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
                    .redacted(reason: .placeholder)
                } else if !displayedPools.isEmpty {
                    Section(header: Text("Origin Pools (\(displayedPools.count))")) {
                        ForEach(displayedPools) { pool in
                            poolRow(pool)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        HIGFeedback.impact(.medium)
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
            } else {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section {
                        ForEach(LBMonitor.placeholders) { placeholderMon in
                            monRow(placeholderMon)
                        }
                    }
                    .redacted(reason: .placeholder)
                } else if !displayedMonitors.isEmpty {
                    Section(header: Text("Health Monitors (\(displayedMonitors.count))")) {
                        ForEach(displayedMonitors) { mon in
                            monRow(mon)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        HIGFeedback.impact(.medium)
                                        Task {
                                            await viewModel.deleteMonitor(monitorId: mon.id)
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
                if let errorMessage = viewModel.errorMessage, (viewModel.loadBalancers.isEmpty && viewModel.pools.isEmpty && viewModel.monitors.isEmpty) {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchData() }
                            }
                        )
                    )
                } else if selectedTab == 0 && viewModel.loadBalancers.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Load Balancers",
                            systemImage: "arrow.triangle.branch",
                            description: "Distribute your traffic across multiple server pools with automatic failover.",
                            actionTitle: "Add Load Balancer",
                            action: { showingAddSheet = true }
                        )
                    )
                } else if selectedTab == 1 && viewModel.pools.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Origin Pools",
                            systemImage: "server.rack",
                            description: "Create origin pools to group backend servers together.",
                            actionTitle: "Add Pool",
                            action: { showingAddSheet = true }
                        )
                    )
                } else if selectedTab == 2 && viewModel.monitors.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Health Monitors",
                            systemImage: "waveform.path.ecg",
                            description: "Send automated HTTP/HTTPS health checks to your origin servers.",
                            actionTitle: "Add Monitor",
                            action: { showingAddSheet = true }
                        )
                    )
                } else if !searchText.isEmpty && ((selectedTab == 0 && displayedLoadBalancers.isEmpty) || (selectedTab == 1 && displayedPools.isEmpty) || (selectedTab == 2 && displayedMonitors.isEmpty)) {
                    HIGContentState(.search(query: searchText))
                }
            }
        }
    }
    
    @ViewBuilder
    private func lbRow(_ lb: LoadBalancer) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(lb.name ?? lb.id)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
                HIGBadge(lb.enabled == true ? .active : .custom(color: .secondary, text: "Inactive"), isCompact: true)
            }
            if let fallback = lb.fallbackPool {
                Text("Fallback: \(fallback)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
    
    @ViewBuilder
    private func poolRow(_ pool: LBPool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(pool.name ?? pool.id)
                    .font(.body.weight(.medium))
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
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                }
            }
        }
        .padding(.vertical, 3)
    }
    
    @ViewBuilder
    private func monRow(_ monitor: LBMonitor) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(monitor.description ?? monitor.id)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
                HIGBadge(.custom(color: .blue, text: monitor.type?.uppercased() ?? "HTTP"), isCompact: true)
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
        .padding(.vertical, 3)
    }
}

// MARK: - AddLBPoolSheetView (Inlined & Cohesive)

struct AddLBPoolSheetView: View {
    @ObservedObject var viewModel: LoadBalancerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var poolName = ""
    @State private var description = ""
    @State private var originName = "origin-1"
    @State private var originAddress = "1.2.3.4"
    @State private var originWeight = 1.0
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Pool Details")) {
                    TextField("Pool Name (e.g. primary-cluster)", text: $poolName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    TextField("Description (Optional)", text: $description)
                        .submitLabel(.next)
                }
                
                Section(header: Text("Initial Origin Server")) {
                    TextField("Origin Name (e.g. srv-01)", text: $originName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    TextField("IP or Hostname (e.g. 192.0.2.1)", text: $originAddress)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Origin Pool")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            let origin = LBOrigin(id: nil, name: originName, address: originAddress, enabled: true, weight: originWeight)
                            let update = LBPoolUpdate(
                                name: poolName,
                                description: description.isEmpty ? nil : description,
                                enabled: true,
                                minimumOrigins: 1,
                                monitor: nil,
                                origins: [origin]
                            )
                            let success = await viewModel.createPool(payload: update)
                            if success {
                                HIGFeedback.success()
                                dismiss()
                            } else {
                                HIGFeedback.error()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(poolName.isEmpty || originAddress.isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}

// MARK: - AddLBMonitorSheetView (Inlined & Cohesive)

struct AddLBMonitorSheetView: View {
    @ObservedObject var viewModel: LoadBalancerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var monitorType = "http"
    @State private var path = "/healthz"
    @State private var expectedCodes = "200"
    @State private var interval = 60
    @State private var timeout = 5
    @State private var retries = 2
    @State private var isSaving = false
    
    let monitorTypes = ["http", "https", "tcp", "udp_icmp", "icmp_ping"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Monitor Type")) {
                    Picker("Type", selection: $monitorType) {
                        ForEach(monitorTypes, id: \.self) { t in
                            Text(t.uppercased()).tag(t)
                        }
                    }
                }
                
                Section(header: Text("Health Check Request")) {
                    TextField("Path (e.g. /healthz)", text: $path)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    TextField("Expected Status Code (e.g. 200 or 2xx)", text: $expectedCodes)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                
                Section(header: Text("Check Timing")) {
                    Stepper("Interval: \(interval)s", value: $interval, in: 10...300, step: 10)
                    Stepper("Timeout: \(timeout)s", value: $timeout, in: 1...30)
                    Stepper("Retries: \(retries)", value: $retries, in: 1...5)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Health Monitor")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            let update = LBMonitorUpdate(
                                type: monitorType,
                                description: "\(monitorType.uppercased()) on \(path)",
                                method: "GET",
                                path: path,
                                port: nil,
                                retries: retries,
                                timeout: timeout,
                                interval: interval,
                                expectedCodes: expectedCodes
                            )
                            let success = await viewModel.createMonitor(payload: update)
                            if success {
                                HIGFeedback.success()
                                dismiss()
                            } else {
                                HIGFeedback.error()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(path.isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
