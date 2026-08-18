import SwiftUI

struct EmailRoutingView: View {
    let zoneId: String
    let zoneName: String
    
    @StateObject private var viewModel: EmailRoutingViewModel
    @State private var showingAddSheet = false
    @State private var searchText = ""
    
    init(zoneId: String, zoneName: String = "") {
        self.zoneId = zoneId
        self.zoneName = zoneName
        _viewModel = StateObject(wrappedValue: EmailRoutingViewModel(zoneId: zoneId))
    }
    
    private var displayedRules: [EmailRoutingRule] {
        if searchText.isEmpty { return viewModel.rules }
        return viewModel.rules.filter {
            ($0.name ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.matchAddress ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.forwardTo ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("Status")) {
                HStack {
                    Text("Email Routing")
                        .font(.body.weight(.medium))
                    Spacer()
                    if let settings = viewModel.settings {
                        CloudnsBadge(settings.isEnabled ? .active("Enabled") : .custom(color: .secondary, text: "Disabled"), isCompact: true)
                    } else {
                        CloudnsBadge(.custom(color: .secondary, text: "Unknown"), isCompact: true)
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
                    .accessibilityLabel("Add Email Rule")
                }
            ) {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    ForEach(EmailRoutingRule.placeholders) { placeholderRule in
                        ruleRow(placeholderRule)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                } else if displayedRules.isEmpty {
                    Text(searchText.isEmpty ? "No routing rules configured." : "No matching email rules found.")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(displayedRules) { rule in
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
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Email Rules")
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
                        .foregroundStyle(.primary)
                } else if rule.isCatchAll {
                    Text("Catch-all")
                        .font(.body)
                        .foregroundStyle(.primary)
                } else {
                    Text(rule.name ?? "Rule")
                        .font(.body)
                        .foregroundStyle(.primary)
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
