import SwiftUI

struct ZonesListView: View {
    @StateObject private var viewModel = ZonesViewModel()
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @State private var searchText = ""
    @State private var zoneToDelete: Zone?
    @State private var showingDeleteAlert = false
    @State private var showAddZoneSheet = false
    
    private var displayedZones: [Zone] {
        viewModel.filteredZones(query: searchText)
    }
    
    var body: some View {
        NavigationStack {
            listViewContent
                .navigationTitle("My Domains")
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: viewModel.totalCount > 0 ? "Search \(viewModel.totalCount) domains" : "Search domains")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.addZoneError = nil
                            showAddZoneSheet = true
                        }) {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("添加域名")
                    }
                }
                .sheet(isPresented: $showAddZoneSheet) {
                    AddZoneView(viewModel: viewModel, isPresented: $showAddZoneSheet)
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ZoneDeleted"))) { _ in
            Task { await viewModel.fetchZones(isRefresh: true) }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ZoneUpdated"))) { _ in
            Task { await viewModel.fetchZones(isRefresh: true) }
        }
        .task {
            if viewModel.zones.isEmpty {
                await viewModel.fetchZones()
            }
        }
        .alert("Remove Zone", isPresented: $showingDeleteAlert, actions: {
            Button("Remove", role: .destructive) {
                if let zone = zoneToDelete {
                    Task {
                        await viewModel.deleteZone(zoneId: zone.id)
                        ToastManager.shared.showSuccess("Domain Removed", message: "\(zone.name) was removed.")
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        }, message: {
            Text("Are you sure you want to remove \(zoneToDelete?.name ?? "this zone") from Cloudflare? This action cannot be undone and will permanently delete all DNS records and settings.")
        })
    }
    
    @ViewBuilder
    private var listViewContent: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)

            if !viewModel.hasFetchedData {
                List {
                    ForEach(0..<6, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
                .listStyle(.insetGrouped)
            } else if let errorMessage = viewModel.errorMessage, viewModel.zones.isEmpty {
                EmptyStateView.error(
                    message: LocalizedStringKey(errorMessage),
                    retryAction: {
                        Task {
                            await viewModel.fetchZones(isRefresh: true)
                        }
                    }
                )
            } else if viewModel.zones.isEmpty {
                EmptyStateView(
                    icon: "globe",
                    title: "No Domains Found",
                    message: "You haven't added any domains to this account yet.",
                    actionTitle: "Add Domain",
                    action: {
                        viewModel.addZoneError = nil
                        showAddZoneSheet = true
                    }
                )
            } else if displayedZones.isEmpty {
                EmptyStateView.search(query: searchText) {
                    searchText = ""
                }
            } else {
                List {
                    Section {
                        ForEach(displayedZones) { zone in
                            NavigationLink(destination: ZoneDetailView(zone: zone)) {
                                ZoneRowView(zone: zone)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    zoneToDelete = zone
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }

                        if viewModel.canLoadMore && searchText.isEmpty {
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
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.fetchZones(isRefresh: true)
                }
            }
        }
    }
}

struct AddZoneView: View {
    @ObservedObject var viewModel: ZonesViewModel
    @Binding var isPresented: Bool

    @State private var domainName: String = ""
    @State private var isSubmitting: Bool = false
    @State private var createdZone: Zone? = nil

    var body: some View {
        if let zone = createdZone {
            NavigationStack {
                // ── Step 2: Nameserver Setup Guide ────────────────────
                List {
                    // Header
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 52))
                                .foregroundStyle(.green)

                            VStack(spacing: 6) {
                                Text("\(zone.name) Added")
                                    .font(.title2)
                                Text("Update your nameservers at your domain registrar to activate Cloudflare protection.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }

                    // Nameservers
                    Section(header: Text("Replace your current nameservers with")) {
                        ForEach(zone.nameServers ?? [], id: \.self) { ns in
                            HStack {
                                Image(systemName: "server.rack")
                                    .foregroundStyle(.blue)
                                    .frame(width: 28)
                                Text(ns)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = ns
                                    ToastManager.shared.showCopied("Nameserver copied")
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Button {
                            UIPasteboard.general.string = (zone.nameServers ?? []).joined(separator: "\n")
                            ToastManager.shared.showCopied("All nameservers copied")
                        } label: {
                            Label("Copy All Nameservers", systemImage: "doc.on.doc.fill")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                        }
                        .foregroundStyle(.blue)
                    }

                    // Instructions
                    Section(header: Text("What to do next")) {
                        Label("Log in to your domain registrar (e.g. GoDaddy, Namecheap, Aliyun)", systemImage: "1.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Label("Find the DNS or Nameserver settings for \(zone.name)", systemImage: "2.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Label("Replace existing nameservers with the Cloudflare ones above", systemImage: "3.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Label("Save and wait for propagation (up to 24 hours)", systemImage: "4.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Section(
                        footer: Text("Your domain will show as Pending until Cloudflare detects the nameserver update. This can take a few minutes to 24 hours.")
                    ) {
                        EmptyView()
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Setup Nameservers")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            isPresented = false
                        }
                        .fontWeight(.bold)
                    }
                }
                .toastContainer()
            }
        } else {
            NavigationStack {
                // ── Step 1: Enter Domain Name ─────────────────────────
                Form {
                    Section(
                        header: Text("Domain Information"),
                        footer: Text("Enter the root domain you want to add to Cloudflare, e.g. example.com")
                    ) {
                        TextField("example.com", text: $domainName)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    if let error = viewModel.addZoneError {
                        Section {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .accessibilityHidden(true)
                                Text(error)
                                    .foregroundStyle(.primary)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .navigationTitle("Add Domain")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Add") {
                            Task {
                                isSubmitting = true
                                let zone = await viewModel.addZone(
                                    name: domainName.trimmingCharacters(in: .whitespacesAndNewlines)
                                )
                                isSubmitting = false
                                if let zone = zone {
                                    createdZone = zone
                                }
                            }
                        }
                        .disabled(domainName.isEmpty || isSubmitting)
                        .fontWeight(.bold)
                    }
                }
                .overlay {
                    if isSubmitting {
                        ZStack {
                            Color.black.opacity(0.15).ignoresSafeArea()
                            VStack(spacing: 12) {
                                ProgressView()
                                    .controlSize(.large)
                                Text("Adding domain...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(24)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                        }
                    }
                }
                .toastContainer()
            }
        }
    }
}

struct ZoneRowView: View {
    let zone: Zone
    
    private var initialChar: String {
        guard let first = zone.name.first else { return "D" }
        return String(first).uppercased()
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Leading Initial Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 38, height: 38)
                Text(initialChar)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(zone.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                // Professional Warning Badges (Only show when active)
                if zone.paused || (zone.developmentMode ?? 0) > 0 {
                    HStack(spacing: 6) {
                        if zone.paused {
                            Text("Paused")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.15))
                                .foregroundStyle(.red)
                                .cornerRadius(4)
                        }
                        
                        if (zone.developmentMode ?? 0) > 0 {
                            Text("Dev Mode")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundStyle(.orange)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Status Badge
            if zone.status == "active" {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                    Text("Active")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.15))
                .foregroundStyle(.green)
                .cornerRadius(10)
            } else {
                Text(zone.status.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.15))
                    .foregroundStyle(.secondary)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ZonesListView()
}
