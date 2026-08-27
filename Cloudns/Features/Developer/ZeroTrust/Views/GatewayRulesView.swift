import Foundation
import SwiftUI

struct GatewayRulesView: View {
    // MARK: - Properties
    let accountId: String
    @StateObject private var viewModel: GatewayRulesViewModel
    @State private var ruleToDelete: GatewayRule?
    @State private var showingDeleteAlert = false
    @State private var showingAddSheet = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: GatewayRulesViewModel(accountId: accountId))
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $viewModel.searchText,
                prompt: "Search Rules"
            )
            .padding(.horizontal, CloudnsSpacing.md)
            .padding(.top, CloudnsSpacing.sm)
            .padding(.bottom, CloudnsSpacing.xs)
            .background(CloudnsColor.groupedBackground)
            
            List {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section {
                        ForEach(GatewayRule.placeholders) { placeholder in
                            ruleRow(placeholder)
                        }
                    }
                    .skeletonLoading(true)
                } else if !viewModel.filteredRules.isEmpty {
                Section(header: Text("Security Rules (\(viewModel.rules.count))")) {
                    ForEach(viewModel.filteredRules) { rule in
                        ruleRow(rule)
                            .contentShape(Rectangle())
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = rule.name
                                    HapticManager.notification(.success)
                                    CloudnsToastManager.shared.showCopied("Rule name copied")
                                } label: {
                                    Label("Copy Rule Name", systemImage: "doc.on.doc")
                                }
                                
                                if let traffic = rule.traffic, !traffic.isEmpty {
                                    Button {
                                        UIPasteboard.general.string = traffic
                                        HapticManager.notification(.success)
                                        CloudnsToastManager.shared.showCopied("Traffic expression copied")
                                    } label: {
                                        Label("Copy Traffic Expression", systemImage: "doc.on.doc")
                                    }
                                }
                                
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    ruleToDelete = rule
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete Rule", systemImage: "trash")
                                }
                            }
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
        .scrollDismissesKeyboard(.interactively)
        .centerConstrainedWidth(maxWidth: 840)
    }
    .background(CloudnsColor.groupedBackground)
        .navigationTitle("Gateway Rules")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Gateway Rule")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddGatewayRuleSheetView(viewModel: viewModel)
        }
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
        .overlay {
            if viewModel.hasFetchedData {
                if let err = viewModel.errorMessage, viewModel.rules.isEmpty {
                    CloudnsStateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(err),
                            retryAction: { Task { await viewModel.fetchRules() } }
                        )
                    )
                } else if viewModel.rules.isEmpty {
                    CloudnsStateOverlayView(
                        state: .empty(
                            icon: "shield.lefthalf.filled",
                            title: "No Gateway Rules",
                            message: "Gateway rules enforce security and DNS filtering policies on zero-trust traffic.",
                            actionTitle: "Refresh",
                            action: { Task { await viewModel.fetchRules() } }
                        )
                    )
                } else if viewModel.filteredRules.isEmpty && !viewModel.searchText.isEmpty {
                    CloudnsStateOverlayView(
                        state: .search(
                            query: viewModel.searchText,
                            clearAction: { viewModel.searchText = "" }
                        )
                    )
                }
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchRules()
            }
        }
    }
    
    @ViewBuilder
    // MARK: - Private Views
    private func ruleRow(_ rule: GatewayRule) -> some View {
        HStack(spacing: CloudnsSpacing.mdSmall) {
            Image(systemName: "shield.lefthalf.filled")
                .foregroundStyle(.teal)
                .font(.title3)
                .frame(width: CloudnsSize.controlHeightSmall, height: CloudnsSize.controlHeightSmall)
                .background(Color.teal.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(rule.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let traffic = rule.traffic, !traffic.isEmpty {
                    Text(traffic)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            CloudnsBadge(.custom(color: ruleActionColor(rule.action), text: rule.action.uppercased()), isCompact: true)
        }
        .padding(.vertical, CloudnsSpacing.xxs)
    }
    
    // MARK: - Actions
    private func ruleActionColor(_ action: String) -> Color {
        switch action.lowercased() {
        case "block": return .red
        case "allow": return .green
        case "isolate": return .purple
        default: return .teal
        }
    }
}
