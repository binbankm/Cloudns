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
        return viewModel.loadBalancers.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchText) }
    }
    
    private var displayedPools: [LBPool] {
        if searchText.isEmpty { return viewModel.pools }
        return viewModel.pools.filter {
            ($0.name ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.description ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var displayedMonitors: [LBMonitor] {
        if searchText.isEmpty { return viewModel.monitors }
        return viewModel.monitors.filter {
            ($0.description ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.path ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List {
            Section {
                Picker("Section", selection: $selectedTab) {
                    Text("Load Balancers").tag(0)
                    Text("Pools").tag(1)
                    Text("Monitors").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            
            if selectedTab == 0 {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section(header: Text("Load Balancers")) {
                        ForEach(LoadBalancer.placeholders) { placeholderLB in
                            lbRow(placeholderLB)
                                .redacted(reason: .placeholder)
                                .shimmering()
                        }
                    }
                } else if !displayedLoadBalancers.isEmpty {
                    Section(header: Text("Load Balancers (\(displayedLoadBalancers.count))")) {
                        ForEach(displayedLoadBalancers) { lb in
                            lbRow(lb)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        HapticManager.impact(.medium)
                                        Task {
                                            await viewModel.deleteLoadBalancer(id: lb.id)
                                            ToastManager.shared.showSuccess("Load Balancer Deleted", message: lb.name ?? "")
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
                    Section(header: Text("Origin Pools")) {
                        ForEach(LBPool.placeholders) { placeholderPool in
                            poolRow(placeholderPool)
                                .redacted(reason: .placeholder)
                                .shimmering()
                        }
                    }
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
                    Section(header: Text("Monitors")) {
                        ForEach(LBMonitor.placeholders) { placeholderMon in
                            monRow(placeholderMon)
                                .redacted(reason: .placeholder)
                                .shimmering()
                        }
                    }
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
        .centerConstrainedWidth(maxWidth: 840)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Load Balancers, Pools, Monitors")
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.loadBalancers.isEmpty && viewModel.pools.isEmpty && viewModel.monitors.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchData() } }
                        )
                    )
                } else if selectedTab == 0 && viewModel.loadBalancers.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "arrow.triangle.branch",
                            title: "No Load Balancers",
                            message: "Distribute incoming traffic across server pools for high availability.",
                            actionTitle: "Add Load Balancer",
                            action: { showingAddSheet = true }
                        )
                    )
                } else if selectedTab == 1 && viewModel.pools.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "server.rack",
                            title: "No Origin Pools",
                            message: "Group multiple origin servers together with health monitoring.",
                            actionTitle: "Add Pool",
                            action: { showingAddSheet = true }
                        )
                    )
                } else if selectedTab == 2 && viewModel.monitors.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "waveform.path.ecg",
                            title: "No Health Monitors",
                            message: "Send automated HTTP/HTTPS health checks to your origin servers.",
                            actionTitle: "Add Monitor",
                            action: { showingAddSheet = true }
                        )
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
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
            ToolbarItem(placement: .navigationBarTrailing) {
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
                Text(monitor.type?.uppercased() ?? "HTTP")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.12))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
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
                            if success { dismiss() }
                            isSaving = false
                        }
                    }
                    .disabled(poolName.isEmpty || originAddress.isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .toastContainer()
        }
    }
}

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
                            if success { dismiss() }
                            isSaving = false
                        }
                    }
                    .disabled(path.isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .toastContainer()
        }
    }
}
