import SwiftUI

// MARK: - LoadBalancerView
// Apple HIG Compliant Cloudflare Global Load Balancers, Origin Server Pools & Health Monitors

struct LoadBalancerView: View {
    let zoneId: String
    
    @StateObject private var viewModel: LoadBalancerViewModel
    @State private var selectedTab = 0
    @State private var showingAddSheet = false
    @State private var lbToDelete: LoadBalancer?
    @State private var poolToDelete: LBPool?
    @State private var monitorToDelete: LBMonitor?
    @State private var showingDeleteDialog = false
    
    init(zoneId: String) {
        self.zoneId = zoneId
        _viewModel = StateObject(wrappedValue: LoadBalancerViewModel(zoneId: zoneId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedTab) {
                Text("Load Balancers").tag(0)
                Text("Pools").tag(1)
                Text("Monitors").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            
            contentList
        }
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
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Load Balancing Resource")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            Group {
                if selectedTab == 0 {
                    AddLoadBalancerView(zoneId: zoneId, viewModel: viewModel)
                } else if selectedTab == 1 {
                    AddLBPoolSheetView(viewModel: viewModel)
                } else {
                    AddLBMonitorSheetView(viewModel: viewModel)
                }
            }
        }
        .confirmationDialog(
            "Delete Resource",
            isPresented: $showingDeleteDialog,
            titleVisibility: .visible
        ) {
            if let lb = lbToDelete {
                let name = (lb.name?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { s in s.isEmpty ? nil : s } ?? String(localized: "Load Balancer")
                Button("Delete '\(name)'", role: .destructive) {
                    Task {
                        await viewModel.deleteLoadBalancer(id: lb.id)
                        ToastManager.shared.showSuccess("Load Balancer Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                        lbToDelete = nil
                    }
                }
            } else if let pool = poolToDelete {
                let name = (pool.name?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { s in s.isEmpty ? nil : s } ?? String(localized: "Pool")
                Button("Delete '\(name)'", role: .destructive) {
                    Task {
                        await viewModel.deletePool(poolId: pool.id)
                        ToastManager.shared.showSuccess("Origin Pool Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                        poolToDelete = nil
                    }
                }
            } else if let mon = monitorToDelete {
                let name = (mon.description?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { s in s.isEmpty ? nil : s } ?? String(localized: "Monitor")
                Button("Delete '\(name)'", role: .destructive) {
                    Task {
                        await viewModel.deleteMonitor(monitorId: mon.id)
                        ToastManager.shared.showSuccess("Health Monitor Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                        monitorToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                lbToDelete = nil
                poolToDelete = nil
                monitorToDelete = nil
            }
        } message: {
            if let lb = lbToDelete {
                let name = (lb.name?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { s in s.isEmpty ? nil : s } ?? String(localized: "Resource")
                Text("Are you sure you want to delete Load Balancer '\(name)'?")
            } else if let pool = poolToDelete {
                let name = (pool.name?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { s in s.isEmpty ? nil : s } ?? String(localized: "Resource")
                Text("Are you sure you want to delete Origin Pool '\(name)'?")
            } else if let mon = monitorToDelete {
                let name = (mon.description?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { s in s.isEmpty ? nil : s } ?? String(localized: "Resource")
                Text("Are you sure you want to delete Health Monitor '\(name)'?")
            }
        }
    }
    
    @ViewBuilder
    private var contentList: some View {
        List {
            if selectedTab == 0 {
                if !viewModel.loadBalancers.isEmpty {
                    Section("Load Balancers (\(viewModel.loadBalancers.count))") {
                        ForEach(viewModel.loadBalancers) { lb in
                            lbRow(lb)
                                .contextMenu {
                                    if let name = lb.name {
                                        Button {
                                            copyToClipboard(name, toast: "Hostname Copied")
                                        } label: {
                                            Label("Copy Hostname", systemImage: "doc.on.doc")
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        lbToDelete = lb
                                        showingDeleteDialog = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete Load Balancer", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        lbToDelete = lb
                                        showingDeleteDialog = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            } else if selectedTab == 1 {
                if !viewModel.pools.isEmpty {
                    Section("Origin Pools (\(viewModel.pools.count))") {
                        ForEach(viewModel.pools) { pool in
                            poolRow(pool)
                                .contextMenu {
                                    if let name = pool.name {
                                        Button {
                                            copyToClipboard(name, toast: "Pool Name Copied")
                                        } label: {
                                            Label("Copy Pool Name", systemImage: "doc.on.doc")
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        poolToDelete = pool
                                        showingDeleteDialog = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete Pool", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        poolToDelete = pool
                                        showingDeleteDialog = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            } else {
                if !viewModel.monitors.isEmpty {
                    Section("Health Monitors (\(viewModel.monitors.count))") {
                        ForEach(viewModel.monitors) { mon in
                            monRow(mon)
                                .contextMenu {
                                    if let desc = mon.description {
                                        Button {
                                            copyToClipboard(desc, toast: "Monitor Description Copied")
                                        } label: {
                                            Label("Copy Description", systemImage: "doc.on.doc")
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        monitorToDelete = mon
                                        showingDeleteDialog = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete Monitor", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        monitorToDelete = mon
                                        showingDeleteDialog = true
                                        HapticManager.impact(.medium)
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
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Load Balancers…",
            error: (viewModel.loadBalancers.isEmpty && viewModel.pools.isEmpty && viewModel.monitors.isEmpty) ? viewModel.errorMessage : nil,
            isEmpty: viewModel.hasFetchedData && isCurrentTabEmpty,
            empty: currentEmptyConfig,
            onRetry: {
                Task { await viewModel.fetchData() }
            }
        )
    }
    
    private var isCurrentTabEmpty: Bool {
        if selectedTab == 0 { return viewModel.loadBalancers.isEmpty }
        if selectedTab == 1 { return viewModel.pools.isEmpty }
        return viewModel.monitors.isEmpty
    }
    
    private var currentEmptyConfig: EmptyStateConfig {
        if selectedTab == 0 {
            return EmptyStateConfig(
                title: "No Load Balancers",
                systemImage: "arrow.triangle.branch",
                description: "Distribute your traffic across multiple server pools with automatic failover.",
                actionTitle: "Add Load Balancer",
                action: { showingAddSheet = true }
            )
        } else if selectedTab == 1 {
            return EmptyStateConfig(
                title: "No Origin Pools",
                systemImage: "server.rack",
                description: "Create origin pools to group backend servers together.",
                actionTitle: "Add Pool",
                action: { showingAddSheet = true }
            )
        } else {
            return EmptyStateConfig(
                title: "No Health Monitors",
                systemImage: "waveform.path.ecg",
                description: "Send automated HTTP/HTTPS health checks to your origin servers.",
                actionTitle: "Add Monitor",
                action: { showingAddSheet = true }
            )
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
                let isActive = lb.enabled == true
                Text(isActive ? LocalizedStringKey("Active") : LocalizedStringKey("Inactive"))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isActive ? Color.green : Color.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill((isActive ? Color.green : Color.secondary).opacity(0.12)))
            }
            if let fallback = lb.fallbackPool {
                Text("Fallback: \(fallback)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
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
                        Text(verbatim: o.name ?? o.address ?? "-")
                            .font(.caption2.monospaced())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.secondarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    private func monRow(_ monitor: LBMonitor) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(monitor.description ?? monitor.id)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
                Text(monitor.type?.uppercased() ?? "HTTP")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.blue.opacity(0.12)))
            }
            HStack {
                Text(monitor.method ?? "GET")
                    .font(.caption.weight(.semibold))
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
        .padding(.vertical, 2)
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
                Section("Pool Details") {
                    TextField("Pool Name (e.g. primary-cluster)", text: $poolName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    TextField("Description (Optional)", text: $description)
                        .submitLabel(.next)
                }
                
                Section("Initial Origin Server") {
                    TextField("Origin Name (e.g. srv-01)", text: $originName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    TextField("IP or Hostname (e.g. 192.0.2.1)", text: $originAddress)
                        .font(.body.monospaced())
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
                                HapticManager.notification(.success)
                                ToastManager.shared.showSuccess("Origin Pool Created", icon: "server.rack")
                                dismiss()
                            } else {
                                HapticManager.notification(.error)
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
                Section("Monitor Type") {
                    Picker("Type", selection: $monitorType) {
                        ForEach(monitorTypes, id: \.self) { t in
                            Text(t.uppercased()).tag(t)
                        }
                    }
                }
                
                Section("Health Check Request") {
                    TextField("Path (e.g. /healthz)", text: $path)
                        .font(.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    TextField("Expected Status Code (e.g. 200 or 2xx)", text: $expectedCodes)
                        .font(.body.monospacedDigit())
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                
                Section("Check Timing") {
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
                                HapticManager.notification(.success)
                                ToastManager.shared.showSuccess("Health Monitor Created", icon: "waveform.path.ecg")
                                dismiss()
                            } else {
                                HapticManager.notification(.error)
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
