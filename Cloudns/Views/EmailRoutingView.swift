import SwiftUI

struct EmailRoutingView: View {
    let zoneId: String
    let zoneName: String
    
    @StateObject private var viewModel: EmailRoutingViewModel
    @State private var showingAddSheet = false
    
    init(zoneId: String, zoneName: String = "") {
        self.zoneId = zoneId
        self.zoneName = zoneName
        _viewModel = StateObject(wrappedValue: EmailRoutingViewModel(zoneId: zoneId))
    }
    
    var body: some View {
        List {
            if viewModel.isLoading && !viewModel.hasFetchedData {
                Section {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                Section {
                    EmptyStateView.error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task {
                                await viewModel.fetchData()
                            }
                        }
                    )
                }
                .listRowBackground(Color.clear)
            } else {
                Section(header: Text("Status")) {
                    HStack {
                        Text("Email Routing")
                        Spacer()
                        if let settings = viewModel.settings {
                            if settings.isEnabled {
                                Text("Enabled")
                                    .foregroundStyle(.green)
                            } else {
                                Text("Disabled")
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Unknown")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section(
                    header: HStack {
                        Text("Routing Rules")
                        Spacer()
                        Button(action: {
                            showingAddSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.caption.bold())
                        }
                    }
                ) {
                    if viewModel.rules.isEmpty {
                        Text("No routing rules configured.")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(viewModel.rules) { rule in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    if let match = rule.matchAddress {
                                        Text(match)
                                            .font(.body)
                                    } else if rule.isCatchAll {
                                        Text("Catch-all")
                                            .font(.body)
                                    } else {
                                        Text(rule.name ?? "Rule")
                                            .font(.body)
                                    }
                                    Spacer()
                                    if rule.isEnabled {
                                        Text("Active")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.2))
                                            .foregroundStyle(.green)
                                            .clipShape(Capsule())
                                    } else {
                                        Text("Disabled")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.gray.opacity(0.2))
                                            .foregroundStyle(.secondary)
                                            .clipShape(Capsule())
                                    }
                                }
                                
                                HStack {
                                    Image(systemName: "arrow.turn.down.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(rule.actionSummary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteRule(ruleId: rule.id)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Destination Addresses")) {
                    if viewModel.destinations.isEmpty {
                        Text("No destination addresses configured.")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(viewModel.destinations) { dest in
                            HStack {
                                Text(dest.email)
                                Spacer()
                                if dest.isVerified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Text("Unverified")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Email Routing")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddSheet) {
            AddEmailRuleView(viewModel: viewModel, zoneName: zoneName)
        }
        .task {
            await viewModel.fetchData()
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        ), actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        })
    }
}
