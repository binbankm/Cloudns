import SwiftUI

struct LoadBalancerView: View {
    let zoneId: String
    
    @StateObject private var viewModel: LoadBalancerViewModel
    @State private var selectedTab = 0
    @State private var showingAddSheet = false
    
    init(zoneId: String) {
        self.zoneId = zoneId
        _viewModel = StateObject(wrappedValue: LoadBalancerViewModel(zoneId: zoneId))
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedTab) {
                    Text("Load Balancers").tag(0)
                    Text("Pools").tag(1)
                    Text("Monitors").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if viewModel.isLoading && !viewModel.hasFetchedData {
                    List {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonRowView()
                        }
                    }
                    .listStyle(.insetGrouped)
                } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                    EmptyStateView.error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task {
                                await viewModel.fetchData()
                            }
                        }
                    )
                } else if selectedTab == 0 && viewModel.loadBalancers.isEmpty {
                    EmptyStateView(
                        icon: "arrow.triangle.branch",
                        title: "No Load Balancers",
                        message: "Distribute incoming traffic across server pools for high availability.",
                        actionTitle: "Add Load Balancer",
                        action: { showingAddSheet = true }
                    )
                } else if selectedTab == 1 && viewModel.pools.isEmpty {
                    EmptyStateView(
                        icon: "server.rack",
                        title: "No Origin Pools",
                        message: "Group multiple origin servers together with health monitoring."
                    )
                } else if selectedTab == 2 && viewModel.monitors.isEmpty {
                    EmptyStateView(
                        icon: "waveform.path.ecg",
                        title: "No Health Monitors",
                        message: "Send automated HTTP/HTTPS health checks to your origin servers."
                    )
                } else {
                    List {
                        if selectedTab == 0 {
                            ForEach(viewModel.loadBalancers) { lb in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(lb.name ?? lb.id)
                                            .font(.body)
                                        Spacer()
                                        if lb.enabled == true {
                                            Text("Active")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        } else {
                                            Text("Inactive")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    if let fallback = lb.fallbackPool {
                                        Text("Fallback: \(fallback)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteLoadBalancer(id: lb.id)
                                            ToastManager.shared.showSuccess("Load Balancer Deleted", message: lb.name ?? "")
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        } else if selectedTab == 1 {
                            ForEach(viewModel.pools) { pool in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(pool.name ?? pool.id)
                                            .font(.body)
                                        Spacer()
                                        Text("\(pool.origins?.count ?? 0) Origins")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    if let desc = pool.description, !desc.isEmpty {
                                        Text(desc)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        } else if selectedTab == 2 {
                            ForEach(viewModel.monitors) { monitor in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(monitor.description ?? monitor.id)
                                        .font(.body)
                                    HStack {
                                        Text(monitor.method ?? "GET")
                                        Text(monitor.path ?? "/")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
        }
        .navigationTitle("Load Balancing")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchData()
        }
        .navigationBarItems(trailing: Button(action: {
            showingAddSheet = true
        }) {
            Image(systemName: "plus")
        })
        .sheet(isPresented: $showingAddSheet) {
            AddLoadBalancerView(zoneId: zoneId, viewModel: viewModel)
        }
        .alert(isPresented: .constant(viewModel.errorMessage != nil)) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK")) {
                    viewModel.errorMessage = nil
                }
            )
        }
    }
}
