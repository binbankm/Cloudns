import Foundation
import SwiftUI

// MARK: - GatewayRulesView
// Apple HIG Compliant Cloudflare Zero Trust Gateway Security Policies (DNS/HTTP)

struct GatewayRulesView: View {
    let accountId: String
    @StateObject private var viewModel: GatewayRulesViewModel
    @State private var ruleToDelete: GatewayRule?
    @State private var showingDeleteAlert = false
    @State private var showingAddSheet = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: GatewayRulesViewModel(accountId: accountId))
    }
    
    var body: some View {
        List {
            if !viewModel.filteredRules.isEmpty {
                Section(header: Text("Security Rules (\(viewModel.rules.count))")) {
                    ForEach(viewModel.filteredRules) { rule in
                        ruleRow(rule)
                            .contentShape(Rectangle())
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = rule.name
                                    ToastManager.shared.showCopied("Rule Name Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy Rule Name", systemImage: "doc.on.doc")
                                }
                                
                                if let traffic = rule.traffic, !traffic.isEmpty {
                                    Button {
                                        UIPasteboard.general.string = traffic
                                        ToastManager.shared.showCopied("Traffic Expression Copied")
                                        HIGFeedback.copied()
                                    } label: {
                                        Label("Copy Traffic Expression", systemImage: "curlybraces")
                                    }
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    HIGFeedback.impact(.medium)
                                    ruleToDelete = rule
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete Rule", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HIGFeedback.impact(.medium)
                                    ruleToDelete = rule
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(HIGColors.error)
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Rules"
        )
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
                .higTouchTarget(44)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddGatewayRuleSheetView(viewModel: viewModel)
                .higToast()
        }
        .confirmationDialog("Delete Rule", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: ruleToDelete) { rule in
            Button("Delete '\(rule.name)'", role: .destructive) {
                Task {
                    await viewModel.deleteRule(id: rule.id)
                    ToastManager.shared.showSuccess("Gateway Rule Deleted", icon: "trash.fill")
                    HIGFeedback.success()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { rule in
            Text("Are you sure you want to delete '\(rule.name)'?")
        }
        .refreshable {
            await viewModel.fetchRules()
        }
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Gateway Rules…"))
            } else if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchRules() } }
                        )
                    )
                } else if viewModel.rules.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Gateway Rules",
                            systemImage: "shield.slash",
                            description: "No Zero Trust Gateway DNS/HTTP policies configured.",
                            actionTitle: "Add Rule",
                            action: { showingAddSheet = true }
                        )
                    )
                } else if viewModel.filteredRules.isEmpty && !viewModel.searchText.isEmpty {
                    HIGContentState(.search(query: viewModel.searchText))
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
    private func ruleRow(_ rule: GatewayRule) -> some View {
        HStack(alignment: .center, spacing: HIGTokens.Spacing.md) {
            ListRowIcon(icon: rule.enabled ? "shield.fill" : "shield.slash", color: rule.enabled ? HIGColors.success : .gray)
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text(rule.name)
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let traffic = rule.traffic, !traffic.isEmpty {
                    Text(traffic)
                        .font(HIGTypography.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            let actionColor: Color = rule.action.lowercased() == "block" ? HIGColors.error : (rule.action.lowercased() == "allow" ? HIGColors.success : .orange)
            HIGBadge(.custom(color: actionColor, text: rule.action.uppercased()), isCompact: true)
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
}

// MARK: - AddGatewayRuleSheetView (Inlined & Cohesive)

struct AddGatewayRuleSheetView: View {
    @ObservedObject var viewModel: GatewayRulesViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var action = "block"
    @State private var traffic = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    let actions = ["block", "allow", "isolate"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Rule Details")) {
                    TextField("Rule Name (e.g. Block Malware)", text: $name)
                        .font(HIGTypography.body)
                    
                    Picker("Action", selection: $action) {
                        ForEach(actions, id: \.self) { act in
                            Text(act.capitalized).tag(act)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Traffic Expression"), footer: Text("Wirefilter expression matching network traffic.")) {
                    TextField("dns.fqdn == \"malicious.com\"", text: $traffic)
                        .font(HIGTypography.body.monospaced())
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                if let err = errorMessage {
                    Section {
                        Text(verbatim: err)
                            .font(HIGTypography.caption)
                            .foregroundStyle(HIGColors.error)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Gateway Rule")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .higTouchTarget(44)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            do {
                                try await viewModel.createRule(
                                    name: name.trimmingCharacters(in: .whitespaces),
                                    action: action,
                                    traffic: traffic.trimmingCharacters(in: .whitespaces)
                                )
                                HIGFeedback.success()
                                ToastManager.shared.showSuccess("Gateway Rule Created", icon: "shield.fill")
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || traffic.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                    .higTouchTarget(44)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
