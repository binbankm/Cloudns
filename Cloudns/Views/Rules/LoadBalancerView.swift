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
            .padding(.horizontal, HIGTokens.Spacing.md)
            .padding(.vertical, HIGTokens.Spacing.sm)
            .background(Color(.systemGroupedBackground))
            
            contentList
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
                .higTouchTarget(44)
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
            .higToast()
        }
        .confirmationDialog(
            "Delete Resource",
            isPresented: $showingDeleteDialog,
            titleVisibility: .visible
        ) {
            if let lb = lbToDelete {
                Button("Delete '\(lb.name ?? "Load Balancer")'", role: .destructive) {
                    Task {
                        await viewModel.deleteLoadBalancer(id: lb.id)
                        ToastManager.shared.showSuccess("Load Balancer Deleted", icon: "trash.fill")
                        HIGFeedback.success()
                        lbToDelete = nil
                    }
                }
            } else if let pool = poolToDelete {
                Button("Delete '\(pool.name ?? "Pool")'", role: .destructive) {
                    Task {
                        await viewModel.deletePool(poolId: pool.id)
                        ToastManager.shared.showSuccess("Origin Pool Deleted", icon: "trash.fill")
                        HIGFeedback.success()
                        poolToDelete = nil
                    }
                }
            } else if let mon = monitorToDelete {
                Button("Delete '\(mon.description ?? "Monitor")'", role: .destructive) {
                    Task {
                        await viewModel.deleteMonitor(monitorId: mon.id)
                        ToastManager.shared.showSuccess("Health Monitor Deleted", icon: "trash.fill")
                        HIGFeedback.success()
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
                Text("Are you sure you want to delete Load Balancer '\(lb.name ?? "Resource")'?")
            } else if let pool = poolToDelete {
                Text("Are you sure you want to delete Origin Pool '\(pool.name ?? "Resource")'?")
            } else if let mon = monitorToDelete {
                Text("Are you sure you want to delete Health Monitor '\(mon.description ?? "Resource")'?")
            }
        }
    }
    
    @ViewBuilder
    private var contentList: some View {
        List {
            if selectedTab == 0 {
                if !viewModel.loadBalancers.isEmpty {
                    Section(header: Text("Load Balancers (\(viewModel.loadBalancers.count))")) {
                        ForEach(viewModel.loadBalancers) { lb in
                            lbRow(lb)
                                .contextMenu {
                                    if let name = lb.name {
                                        Button {
                                            UIPasteboard.general.string = name
                                            ToastManager.shared.showCopied("Hostname Copied")
                                            HIGFeedback.copied()
                                        } label: {
                                            Label("Copy Hostname", systemImage: "doc.on.doc")
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        lbToDelete = lb
                                        showingDeleteDialog = true
                                        HIGFeedback.impact(.medium)
                                    } label: {
                                        Label("Delete Load Balancer", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        lbToDelete = lb
                                        showingDeleteDialog = true
                                        HIGFeedback.impact(.medium)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(HIGColors.error)
                                }
                        }
                    }
                }
            } else if selectedTab == 1 {
                if !viewModel.pools.isEmpty {
                    Section(header: Text("Origin Pools (\(viewModel.pools.count))")) {
                        ForEach(viewModel.pools) { pool in
                            poolRow(pool)
                                .contextMenu {
                                    if let name = pool.name {
                                        Button {
                                            UIPasteboard.general.string = name
                                            ToastManager.shared.showCopied("Pool Name Copied")
                                            HIGFeedback.copied()
                                        } label: {
                                            Label("Copy Pool Name", systemImage: "doc.on.doc")
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        poolToDelete = pool
                                        showingDeleteDialog = true
                                        HIGFeedback.impact(.medium)
                                    } label: {
                                        Label("Delete Pool", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        poolToDelete = pool
                                        showingDeleteDialog = true
                                        HIGFeedback.impact(.medium)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(HIGColors.error)
                                }
                        }
                    }
                }
            } else {
                if !viewModel.monitors.isEmpty {
                    Section(header: Text("Health Monitors (\(viewModel.monitors.count))")) {
                        ForEach(viewModel.monitors) { mon in
                            monRow(mon)
                                .contextMenu {
                                    if let desc = mon.description {
                                        Button {
                                            UIPasteboard.general.string = desc
                                            ToastManager.shared.showCopied("Monitor Description Copied")
                                            HIGFeedback.copied()
                                        } label: {
                                            Label("Copy Description", systemImage: "doc.on.doc")
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        monitorToDelete = mon
                                        showingDeleteDialog = true
                                        HIGFeedback.impact(.medium)
                                    } label: {
                                        Label("Delete Monitor", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        monitorToDelete = mon
                                        showingDeleteDialog = true
                                        HIGFeedback.impact(.medium)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(HIGColors.error)
                                }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Load Balancers…"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.loadBalancers.isEmpty && viewModel.pools.isEmpty && viewModel.monitors.isEmpty {
                HIGContentState(
                    .error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task { await viewModel.fetchData() }
                        }
                    )
                )
            } else if viewModel.hasFetchedData {
                if selectedTab == 0 && viewModel.loadBalancers.isEmpty {
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
                }
            }
        }
    }
    
    @ViewBuilder
    private func lbRow(_ lb: LoadBalancer) -> some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
            HStack {
                Text(lb.name ?? lb.id)
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
                HIGBadge(lb.enabled == true ? .active : .custom(color: .secondary, text: "Inactive"), isCompact: true)
            }
            if let fallback = lb.fallbackPool {
                Text("Fallback: \(fallback)")
                    .font(HIGTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
    
    @ViewBuilder
    private func poolRow(_ pool: LBPool) -> some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
            HStack {
                Text(pool.name ?? pool.id)
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(pool.origins?.count ?? 0) Origins")
                    .font(HIGTypography.caption)
                    .foregroundStyle(.secondary)
            }
            if let desc = pool.description, !desc.isEmpty {
                Text(desc)
                    .font(HIGTypography.caption)
                    .foregroundStyle(.secondary)
            }
            if let origins = pool.origins, !origins.isEmpty {
                HStack(spacing: HIGTokens.Spacing.xs) {
                    ForEach(origins.prefix(3), id: \.idResolved) { o in
                        Text(verbatim: o.name ?? o.address ?? "-")
                            .font(HIGTypography.caption2.monospaced())
                            .padding(.horizontal, HIGTokens.Spacing.xs)
                            .padding(.vertical, HIGTokens.Spacing.xxs)
                            .background(Color(.secondarySystemFill))
                            .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.xs, style: .continuous))
                    }
                }
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
    
    @ViewBuilder
    private func monRow(_ monitor: LBMonitor) -> some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
            HStack {
                Text(monitor.description ?? monitor.id)
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
                HIGBadge(.custom(color: .blue, text: monitor.type?.uppercased() ?? "HTTP"), isCompact: true)
            }
            HStack {
                Text(monitor.method ?? "GET")
                    .font(HIGTypography.caption.weight(.semibold))
                Text(monitor.path ?? "/")
                    .font(HIGTypography.caption.monospaced())
                Spacer()
                if let codes = monitor.expectedCodes {
                    Text("Expect: \(codes)")
                        .font(HIGTypography.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
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
                        .font(HIGTypography.body)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    TextField("Description (Optional)", text: $description)
                        .font(HIGTypography.body)
                        .submitLabel(.next)
                }
                
                Section(header: Text("Initial Origin Server")) {
                    TextField("Origin Name (e.g. srv-01)", text: $originName)
                        .font(HIGTypography.body)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    TextField("IP or Hostname (e.g. 192.0.2.1)", text: $originAddress)
                        .font(HIGTypography.body.monospaced())
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
                        .higTouchTarget(44)
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
                                ToastManager.shared.showSuccess("Origin Pool Created", icon: "server.rack")
                                dismiss()
                            } else {
                                HIGFeedback.error()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(poolName.isEmpty || originAddress.isEmpty || isSaving)
                    .higTouchTarget(44)
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
                        .font(HIGTypography.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    TextField("Expected Status Code (e.g. 200 or 2xx)", text: $expectedCodes)
                        .font(HIGTypography.body.monospacedDigit())
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
                        .higTouchTarget(44)
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
                                ToastManager.shared.showSuccess("Health Monitor Created", icon: "waveform.path.ecg")
                                dismiss()
                            } else {
                                HIGFeedback.error()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(path.isEmpty || isSaving)
                    .higTouchTarget(44)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
