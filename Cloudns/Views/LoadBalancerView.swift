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
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading...")
                    Spacer()
                } else {
                    List {
                        if selectedTab == 0 {
                            if viewModel.loadBalancers.isEmpty {
                                Text("No Load Balancers configured.")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(viewModel.loadBalancers) { lb in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(lb.name ?? lb.id)
                                                .font(.headline)
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
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        } else if selectedTab == 1 {
                            if viewModel.pools.isEmpty {
                                Text("No Pools configured.")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(viewModel.pools) { pool in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(pool.name ?? pool.id)
                                                .font(.headline)
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
                            }
                        } else if selectedTab == 2 {
                            if viewModel.monitors.isEmpty {
                                Text("No Monitors configured.")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(viewModel.monitors) { monitor in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(monitor.description ?? monitor.id)
                                            .font(.headline)
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
