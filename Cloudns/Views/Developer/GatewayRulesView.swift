import Foundation
import SwiftUI

struct GatewayRulesView: View {
    let accountId: String
    @StateObject private var viewModel: GatewayRulesViewModel
    @State private var ruleToDelete: GatewayRule?
    @State private var showingDeleteAlert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: GatewayRulesViewModel(accountId: accountId))
    }
    
    var body: some View {
        Group {
            if !viewModel.hasFetchedData {
                List {
                    Section(header: Text("Security Rules")) {
                        ForEach(GatewayRule.placeholders) { rule in
                            ruleRow(rule)
                                .skeletonLoading(true)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Gateway Rules")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                List {
                    if !viewModel.filteredRules.isEmpty {
                        Section(header: Text("Security Rules (\(viewModel.rules.count))")) {
                            ForEach(viewModel.filteredRules) { rule in
                                ruleRow(rule)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            HapticManager.impact(.medium)
                                            ruleToDelete = rule
                                            showingDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .overlay {
                    if let err = viewModel.errorMessage, viewModel.rules.isEmpty {
                        StateOverlayView(
                            state: .error(
                                message: LocalizedStringKey(err),
                                retryAction: { Task { await viewModel.fetchRules() } }
                            )
                        )
                    } else if viewModel.rules.isEmpty {
                        StateOverlayView(
                            state: .empty(
                                icon: "shield.lefthalf.filled",
                                title: "No Gateway Rules",
                                message: "Gateway rules enforce security and DNS filtering policies on zero-trust traffic.",
                                actionTitle: "Refresh",
                                action: { Task { await viewModel.fetchRules() } }
                            )
                        )
                    } else if viewModel.filteredRules.isEmpty && !viewModel.searchText.isEmpty {
                        StateOverlayView(
                            state: .search(
                                query: viewModel.searchText,
                                clearAction: { viewModel.searchText = "" }
                            )
                        )
                    }
                }
                .navigationTitle("Gateway Rules")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $viewModel.searchText, prompt: "Search Rules")
                .confirmationDialog("Delete Rule", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: ruleToDelete) { rule in
                    Button("Delete '\(rule.name)'", role: .destructive) {
                        Task { await viewModel.deleteRule(id: rule.id) }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: { rule in
                    Text("Are you sure you want to delete '\(rule.name)'?")
                }
                .refreshable {
                    await viewModel.fetchRules()
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.hasFetchedData)
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchRules()
            }
        }
        .toastContainer()
    }
    
    @ViewBuilder
    private func ruleRow(_ rule: GatewayRule) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .foregroundStyle(.teal)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(Color.teal.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(rule.name)
                    .font(.body.weight(.medium))
                
                if let traffic = rule.traffic, !traffic.isEmpty {
                    Text(traffic)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Text(rule.action.uppercased())
                .font(.caption2.weight(.medium))
                .foregroundStyle(ruleActionColor(rule.action))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(ruleActionColor(rule.action).opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.vertical, 2)
    }
    
    private func ruleActionColor(_ action: String) -> Color {
        switch action.lowercased() {
        case "block": return .red
        case "allow": return .green
        case "isolate": return .purple
        default: return .teal
        }
    }
}
