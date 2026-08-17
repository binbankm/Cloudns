import SwiftUI

struct ZonesListView: View {
    @StateObject private var viewModel = ZonesViewModel()
    @AppStorage(AppStorageKey.isLoggedIn) private var isLoggedIn = true
    @State private var searchText = ""
    @State private var zoneToDelete: Zone?
    @State private var showingDeleteAlert = false
    @State private var showAddZoneSheet = false
    
    private var displayedZones: [Zone] {
        viewModel.filteredZones(query: searchText)
    }
    
    var body: some View {
        NavigationStack {
            if !viewModel.hasFetchedData {
                // Skeleton phase: plain list with NO searchable attached
                // This is the industry-standard way to prevent search bar / skeleton overlap
                skeletonContent
                    .navigationTitle("My Domains")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                listViewContent
                    .navigationTitle("My Domains")
                    .navigationBarTitleDisplayMode(.inline)
                    .searchable(
                        text: $searchText,
                        prompt: viewModel.totalCount > 0 ? "Search \(viewModel.totalCount) domains" : "Search domains"
                    )
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                viewModel.addZoneError = nil
                                showAddZoneSheet = true
                            }) {
                                Image(systemName: "plus")
                            }
                            .accessibilityLabel("Add Domain")
                        }
                    }
                    .sheet(isPresented: $showAddZoneSheet) {
                        AddZoneView(viewModel: viewModel, isPresented: $showAddZoneSheet)
                    }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.hasFetchedData)
        .onReceive(NotificationCenter.default.publisher(for: .zoneDeleted)) { _ in
            Task { await viewModel.fetchZones(isRefresh: true) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoneUpdated)) { _ in
            Task { await viewModel.fetchZones(isRefresh: true) }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchZones()
            }
        }
        .confirmationDialog(
            "Remove Zone",
            isPresented: $showingDeleteAlert,
            titleVisibility: .visible,
            presenting: zoneToDelete
        ) { zone in
            Button("Remove '\(zone.name)'", role: .destructive) {
                Task {
                    await viewModel.deleteZone(zoneId: zone.id)
                    ToastManager.shared.showSuccess("Domain Removed", message: "\(zone.name) was removed.")
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: { zone in
            Text("Are you sure you want to remove \(zone.name) from Cloudflare? This action cannot be undone and will permanently delete all DNS records and settings.")
        }
    }
    
    // Skeleton-only list — no .searchable modifier, so no overlap is possible
    @ViewBuilder
    private var skeletonContent: some View {
        List {
            Section {
                ForEach(Zone.placeholders) { placeholderZone in
                    ZoneRowView(zone: placeholderZone)
                }
            }
            .skeletonLoading(true)
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private var listViewContent: some View {
        List {
            if !displayedZones.isEmpty {
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
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.fetchZones(isRefresh: true)
        }
        .overlay {
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
                            message: "You haven't added any domains to this account yet.",
                            actionTitle: "Add Domain",
                            action: {
                                viewModel.addZoneError = nil
                                showAddZoneSheet = true
                            }
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
                                .accessibilityHidden(true)

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
                                    .accessibilityHidden(true)
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
                                .accessibilityLabel("Copy nameserver \(ns)")
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
                            .clipShape(RoundedRectangle(cornerRadius: 16))
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
    
    private var avatarColor: Color {
        let palette: [Color] = [.blue, .indigo, .purple, .teal, .mint, .cyan, .orange, .pink]
        let hash = abs(zone.name.hashValue)
        return palette[hash % palette.count]
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Leading Initial Avatar with Deterministic Color Hashing
            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.14))
                    .frame(width: 38, height: 38)
                Text(initialChar)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(avatarColor)
            }
            .accessibilityHidden(true)
            
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
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        
                        if (zone.developmentMode ?? 0) > 0 {
                            Text("Dev Mode")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundStyle(.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
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
                        .accessibilityHidden(true)
                    Text("Active")
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.15))
                .foregroundStyle(.green)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Text(zone.status.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.15))
                    .foregroundStyle(.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(zone.name), status \(zone.status)")
    }
}

#Preview {
    ZonesListView()
}
