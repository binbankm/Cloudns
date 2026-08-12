import SwiftUI

struct ZonesListView: View {
    @StateObject private var viewModel = ZonesViewModel()
    @AppStorage("isLoggedIn") private var isLoggedIn = true
    @State private var searchText = ""
    @State private var zoneToDelete: Zone?
    @State private var showingDeleteAlert = false
    
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
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredZones) { zone in
                                    NavigationLink(destination: ZoneDetailView(zone: zone)) {
                                        ZoneCardView(zone: zone)
                                    }
                                    .buttonStyle(PlainButtonStyle()) // Removes the default blue highlight and arrow
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
                                            zoneToDelete = zone
                                            showingDeleteAlert = true
                                        } label: {
                                            Label("Remove Zone from Cloudflare", systemImage: "trash")
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                                .animation(.easeInOut, value: filteredZones)
                                
                                if viewModel.canLoadMore && searchText.isEmpty {
                                    ProgressView()
                                        .padding()
                                        .onAppear {
                                            Task {
                                                await viewModel.fetchZones(isRefresh: false)
                                            }
                                        }
                                }
                            }
                            .padding(.vertical, 16)
                        }
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
                            viewModel.isAddingZone = true
                        }) {
                            Image(systemName: "plus")
                        }
                }
            }
            .sheet(isPresented: $viewModel.isAddingZone) {
                AddZoneView(viewModel: viewModel)
            }
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
    @Environment(\.dismiss) var dismiss
    @State private var domainName: String = ""
    @State private var isSubmitting: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Domain Information"), footer: Text("Enter the root domain you want to add to Cloudflare, e.g. example.com")) {
                    TextField("example.com", text: $domainName)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                if let error = viewModel.addZoneError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Add Domain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.isAddingZone = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        Task {
                            isSubmitting = true
                            let success = await viewModel.addZone(name: domainName.trimmingCharacters(in: .whitespacesAndNewlines))
                            isSubmitting = false
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(domainName.isEmpty || isSubmitting)
                    .fontWeight(.bold)
                }
            }
            .overlay {
                if isSubmitting {
                    ProgressView("Adding...")
                        .padding()
                        .background(Color(UIColor.systemBackground).opacity(0.8))
                        .cornerRadius(10)
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
                if zone.paused || zone.developmentMode > 0 {
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
                        
                        if zone.developmentMode > 0 {
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
