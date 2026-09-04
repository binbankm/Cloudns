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
                Section("Security Rules (\(viewModel.rules.count))") {
                    ForEach(viewModel.filteredRules) { rule in
                        ruleRow(rule)
                            .contentShape(Rectangle())
                            .contextMenu {
                                Button {
                                    copyToClipboard(rule.name, toast: "Rule Name Copied")
                                } label: {
                                    Label("Copy Rule Name", systemImage: "doc.on.doc")
                                }
                                
                                if let traffic = rule.traffic, !traffic.isEmpty {
                                    Button {
                                        copyToClipboard(traffic, toast: "Traffic Expression Copied")
                                    } label: {
                                        Label("Copy Traffic Expression", systemImage: "curlybraces")
                                    }
                                }
                                
                                Divider()
                                
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
                                .tint(.red)
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Gateway Rules…",
            isEmpty: viewModel.hasFetchedData && viewModel.rules.isEmpty && viewModel.errorMessage == nil,
            emptyTitle: "No Gateway Rules",
            emptyDescription: "No Zero Trust Gateway DNS/HTTP policies configured.",
            emptyActionTitle: "Add Rule",
            emptyAction: { showingAddSheet = true },
            isSearchEmpty: viewModel.hasFetchedData && !viewModel.rules.isEmpty && viewModel.filteredRules.isEmpty && !viewModel.searchText.isEmpty,
            searchQuery: viewModel.searchText,
            errorMessage: viewModel.errorMessage.map { LocalizedStringKey($0) },
            retryAction: { Task { await viewModel.fetchRules() } }
        )
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
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddGatewayRuleSheetView(viewModel: viewModel)
        }
        .confirmationDialog("Delete Rule", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: ruleToDelete) { rule in
            Button("Delete '\(rule.name)'", role: .destructive) {
                Task {
                    await viewModel.deleteRule(id: rule.id)
                    ToastManager.shared.showSuccess("Gateway Rule Deleted", icon: "trash.fill")
                    HapticManager.notification(.success)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { rule in
            Text("Are you sure you want to delete '\(rule.name)'?")
        }
        .refreshable {
            await viewModel.fetchRules()
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchRules()
            }
        }
    }
    
    @ViewBuilder
    private func ruleRow(_ rule: GatewayRule) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ListRowIcon(icon: rule.enabled ? "shield.fill" : "shield.slash", color: rule.enabled ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let traffic = rule.traffic, !traffic.isEmpty {
                    Text(traffic)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            let actionColor: Color = rule.action.lowercased() == "block" ? .red : (rule.action.lowercased() == "allow" ? .green : .orange)
            Text(rule.action.uppercased())
                .font(.caption2.weight(.medium))
                .foregroundStyle(actionColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(actionColor.opacity(0.12)))
        }
        .padding(.vertical, 2)
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
                Section("Rule Details") {
                    TextField("Rule Name (e.g. Block Malware)", text: $name)
                        .font(.body)
                    
                    Picker("Action", selection: $action) {
                        ForEach(actions, id: \.self) { act in
                            Text(act.capitalized).tag(act)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    TextField("dns.fqdn == \"malicious.com\"", text: $traffic)
                        .font(.body.monospaced())
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Traffic Expression")
                } footer: {
                    Text("Wirefilter expression matching network traffic.")
                }
                
                if let err = errorMessage {
                    Section {
                        Text(verbatim: err)
                            .font(.caption)
                            .foregroundStyle(.red)
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
                                HapticManager.notification(.success)
                                ToastManager.shared.showSuccess("Gateway Rule Created", icon: "shield.fill")
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.notification(.error)
                            }
                            isSaving = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || traffic.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
