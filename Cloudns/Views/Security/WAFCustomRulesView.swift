import SwiftUI

struct WAFCustomRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel = WAFViewModel()
    @State private var showingAddSheet = false
    @State private var searchText = ""
    
    private var displayedRules: [WAFRule] {
        if searchText.isEmpty { return viewModel.rules }
        return viewModel.rules.filter {
            ($0.description ?? "").localizedCaseInsensitiveContains(searchText) ||
            $0.expression.localizedCaseInsensitiveContains(searchText) ||
            $0.action.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List {
            if viewModel.hasFetchedData {
                // Rule Quota Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Custom Rules Quota")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(viewModel.rules.count) / 5 active")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            CloudnsBadge(.free, isCompact: true)
                        }
                        
                        ProgressView(value: Double(viewModel.rules.count), total: 5.0)
                            .tint(viewModel.rules.count >= 5 ? .red : .blue)
                    }
                    .padding(.vertical, 4)
                }
                
                // Managed Rulesets Overview Card
                Section(header: Text("Cloudflare Managed Rulesets")) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "shield.lefthalf.filled")
                                .foregroundStyle(.indigo)
                            Text("Cloudflare Managed Ruleset")
                                .font(.body.weight(.medium))
                            Spacer()
                            CloudnsBadge(.pro, isCompact: true)
                        }
                        Text("Zero-day vulnerability & OWASP top 10 protection maintained directly by Cloudflare Threat Research.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(.purple)
                            Text("Cloudflare OWASP Core Ruleset")
                                .font(.body.weight(.medium))
                            Spacer()
                            CloudnsBadge(.pro, isCompact: true)
                        }
                        Text("Anomaly scoring engine detecting SQLi, XSS, and RCE attacks.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section(header: Text("Custom Rules")) {
                    ForEach(WAFRule.placeholders) { placeholderRule in
                        WAFRuleCardView(rule: placeholderRule, onToggle: {})
                    }
                }
                .skeletonLoading(true)
            } else if !displayedRules.isEmpty {
                Section(header: Text("Custom Rules (\(displayedRules.count))")) {
                    ForEach(displayedRules) { rule in
                        WAFRuleCardView(rule: rule, onToggle: {
                            HapticManager.impact(.light)
                            Task {
                                await viewModel.toggleRule(zoneId: zoneId, rule: rule)
                                ToastManager.shared.showSuccess("WAF Rule Updated", message: "\(rule.description ?? "Rule") status updated")
                            }
                        })
                    }
                    .onDelete(perform: deleteRules)
                }
            } else if viewModel.hasFetchedData && searchText.isEmpty {
                Section(header: Text("Custom Rules")) {
                    VStack(spacing: 12) {
                        Image(systemName: "shield.slash")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                            .padding(.top, 10)
                        
                        Text("No Custom WAF Rules")
                            .font(.headline)
                        
                        Text("You haven't created any custom WAF rules yet. Add a rule to inspect incoming traffic.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            HapticManager.impact(.medium)
                            showingAddSheet = true
                        } label: {
                            Text("Add WAF Rule")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 10)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search WAF Rules")
        .refreshable {
            await viewModel.fetchWAFRules(zoneId: zoneId)
        }
        .navigationTitle("WAF Custom Rules")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchWAFRules(zoneId: zoneId) }
                            }
                        )
                    )
                } else if displayedRules.isEmpty && !searchText.isEmpty {
                    StateOverlayView(
                        state: .search(
                            query: searchText,
                            clearAction: { searchText = "" }
                        )
                    )
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddSheet = true
                }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add WAF Rule")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddWAFRuleView(zoneId: zoneId, viewModel: viewModel)
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchWAFRules(zoneId: zoneId)
            }
        }
    }
    
    private func deleteRules(at offsets: IndexSet) {
        HapticManager.impact(.medium)
        for index in offsets {
            let rule = viewModel.rules[index]
            Task {
                await viewModel.deleteRule(zoneId: zoneId, ruleId: rule.id)
                ToastManager.shared.showSuccess("WAF Rule Deleted", message: rule.description ?? "")
            }
        }
    }
}
