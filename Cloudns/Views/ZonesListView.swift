import SwiftUI

struct ZonesListView: View {
    @StateObject private var viewModel = ZonesViewModel()
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @State private var searchText = ""
    @State private var zoneToDelete: Zone?
    @State private var showingDeleteAlert = false
    @State private var showAddZoneSheet = false
    
    var filteredZones: [Zone] {
        if searchText.isEmpty {
            return viewModel.zones
        } else {
            return viewModel.zones.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                
                Group {
                    if viewModel.isLoading && viewModel.zones.isEmpty {
                        ProgressView("Loading zones...")
                    } else if let errorMessage = viewModel.errorMessage, viewModel.zones.isEmpty {
                        VStack {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                            Button("Retry") {
                                Task {
                                    await viewModel.fetchZones()
                                }
                            }
                        }
                    } else if viewModel.zones.isEmpty {
                        EmptyStateView(
                            icon: "globe",
                            title: "No domains found.",
                            message: "You haven't added any domains to this account yet."
                        )
                    } else if filteredZones.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No Results",
                            message: "No domains match your search."
                        )
                    } else {
                        List {
                            ForEach(filteredZones) { zone in
                                ZStack {
                                    NavigationLink(destination: ZoneDetailView(zone: zone)) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                    
                                    ZoneCardView(zone: zone)
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
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
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .onAppear {
                                        Task {
                                            await viewModel.fetchZones(isRefresh: false)
                                        }
                                    }
                            }
                        }
                        .listStyle(.plain)
                        .refreshable {
                            await viewModel.fetchZones(isRefresh: true)
                        }
                    }
                }
            }
            .navigationTitle("My Domains")
            .searchable(text: $searchText, prompt: viewModel.totalCount > 0 ? "Search \(viewModel.totalCount) domains" : "Search domains")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.addZoneError = nil
                            showAddZoneSheet = true
                        }) {
                            Image(systemName: "plus")
                        }
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
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Remove Zone"),
                message: Text("Are you sure you want to remove \(zoneToDelete?.name ?? "this zone") from Cloudflare? This action cannot be undone and will permanently delete all DNS records and settings."),
                primaryButton: .destructive(Text("Remove")) {
                    if let zone = zoneToDelete {
                        Task {
                            await viewModel.deleteZone(zoneId: zone.id)
                        }
                    }
                },
                secondaryButton: .cancel()
            )
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
                                .foregroundColor(.green)

                            VStack(spacing: 6) {
                                Text("\(zone.name) Added")
                                    .font(.title2.bold())
                                Text("Update your nameservers at your domain registrar to activate Cloudflare protection.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
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
                                    .foregroundColor(.blue)
                                    .frame(width: 28)
                                Text(ns)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.primary)
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = ns
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Button {
                            UIPasteboard.general.string = (zone.nameServers ?? []).joined(separator: "\n")
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Label("Copy All Nameservers", systemImage: "doc.on.doc.fill")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                        }
                        .foregroundColor(.blue)
                    }

                    // Instructions
                    Section(header: Text("What to do next")) {
                        Label("Log in to your domain registrar (e.g. GoDaddy, Namecheap, Aliyun)", systemImage: "1.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Label("Find the DNS or Nameserver settings for \(zone.name)", systemImage: "2.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Label("Replace existing nameservers with the Cloudflare ones above", systemImage: "3.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Label("Save and wait for propagation (up to 24 hours)", systemImage: "4.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
                                    .foregroundColor(.orange)
                                Text(error)
                                    .foregroundColor(.primary)
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
                                    .foregroundColor(.secondary)
                            }
                            .padding(24)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                        }
                    }
                }
            }
        }
    }
}

struct ZoneCardView: View {
    let zone: Zone
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 8) {
                Text(zone.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Professional Warning Badges (Only show when active)
                if zone.paused || (zone.developmentMode ?? 0) > 0 {
                    HStack(spacing: 6) {
                        if zone.paused {
                            Text("Paused")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(4)
                        }
                        
                        if (zone.developmentMode ?? 0) > 0 {
                            Text("Dev Mode")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Status Badge
            if zone.status == "active" {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                    Text("Active")
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Text(zone.status.capitalized)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(UIColor.tertiaryLabel))
                .padding(.leading, 8)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ZonesListView()
}
