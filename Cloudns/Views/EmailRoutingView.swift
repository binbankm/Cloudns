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
            
            if !viewModel.hasFetchedData {
                Section(header: Text("Routing Rules")) {
                    ForEach(EmailRoutingRule.placeholders) { rule in
                        ruleRow(rule)
                    }
                }
                .skeletonLoading(true)
            } else {
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
                        .accessibilityLabel("Add Email Rule")
                    }
                ) {
                    if viewModel.rules.isEmpty {
                        Text("No routing rules configured.")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(viewModel.rules) { rule in
                            ruleRow(rule)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        HapticManager.impact(.medium)
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
                                        .accessibilityHidden(true)
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
        .listStyle(.insetGrouped)
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty && viewModel.destinations.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchData() } }
                        )
                    )
                }
            }
        }
        .navigationTitle("Email Routing")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddSheet) {
            AddEmailRuleView(viewModel: viewModel, zoneName: zoneName)
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchData()
            }
        }
        .refreshable {
            await viewModel.fetchData()
        }
    }
    
    @ViewBuilder
    private func ruleRow(_ rule: EmailRoutingRule) -> some View {
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
                    .accessibilityHidden(true)
                Text(rule.actionSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
