import SwiftUI

struct IPAccessRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel = IPAccessRulesViewModel()
    @State private var showingAddRule = false
    @State private var searchText = ""
    
    private var displayedRules: [IPAccessRule] {
        if searchText.isEmpty { return viewModel.rules }
        return viewModel.rules.filter {
            $0.configuration.value.localizedCaseInsensitiveContains(searchText) ||
            $0.configuration.target.localizedCaseInsensitiveContains(searchText) ||
            $0.mode.localizedCaseInsensitiveContains(searchText) ||
            ($0.notes ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(IPAccessRule.placeholders) { placeholderRule in
                        IPAccessRuleRow(rule: placeholderRule)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
            } else if !displayedRules.isEmpty {
                Section {
                    ForEach(displayedRules) { rule in
                        IPAccessRuleRow(rule: rule)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    Task {
                                        await viewModel.deleteRule(zoneId: zoneId, ruleId: rule.id)
                                        ToastManager.shared.showSuccess("IP Rule Deleted", message: rule.configuration.value)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search IP Rules")
        .refreshable {
            await viewModel.fetchRules(zoneId: zoneId)
        }
        .navigationTitle("IP Access Rules")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchRules(zoneId: zoneId) }
                            }
                        )
                    )
                } else if viewModel.rules.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "network.badge.shield.half.filled",
                            title: "No IP Access Rules",
                            message: "You haven't created any IP access rules yet. Add a rule to block or challenge specific IPs or countries.",
                            actionTitle: "Add IP Rule",
                            action: { showingAddRule = true }
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
                    showingAddRule = true
                }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add IP Rule")
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchRules(zoneId: zoneId)
            }
        }
        .sheet(isPresented: $showingAddRule) {
            AddIPAccessRuleView(zoneId: zoneId, viewModel: viewModel, isPresented: $showingAddRule)
        }
    }
}

struct IPAccessRuleRow: View {
    let rule: IPAccessRule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rule.configuration.value)
                    .font(.body.monospacedDigit())
                
                Spacer()
                
                CloudnsBadge(.custom(color: colorForMode(rule.mode), text: rule.mode.uppercased()), isCompact: true)
            }
            
            HStack {
                Text(rule.configuration.target.uppercased().replacingOccurrences(of: "_", with: " "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let notes = rule.notes, !notes.isEmpty {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorForMode(_ mode: String) -> Color {
        switch mode {
        case "block": return .red
        case "challenge", "js_challenge", "managed_challenge": return .orange
        case "whitelist": return .green
        default: return .blue
        }
    }
}

struct AddIPAccessRuleView: View {
    let zoneId: String
    @ObservedObject var viewModel: IPAccessRulesViewModel
    @Binding var isPresented: Bool
    
    @State private var target = "ip"
    @State private var value = ""
    @State private var mode = "block"
    @State private var notes = ""
    
    enum Field { case value, notes }
    @FocusState private var focusedField: Field?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Target")) {
                    Picker("Target Type", selection: $target) {
                        Text("IP Address").tag("ip")
                        Text("IP Range").tag("ip_range")
                        Text("Country").tag("country")
                        Text("ASN").tag("asn")
                    }
                    
                    TextField(target == "country" ? "e.g. US, CN, GB" : (target == "asn" ? "e.g. AS12345" : "e.g. 192.168.1.1"), text: $value)
                        .keyboardType(target == "asn" ? .numberPad : .asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: .value)
                        .onSubmit { focusedField = .notes }
                }
                
                Section(header: Text("Action")) {
                    Picker("Action", selection: $mode) {
                        Text("Block").tag("block")
                        Text("Managed Challenge").tag("managed_challenge")
                        Text("JS Challenge").tag("js_challenge")
                        Text("Legacy CAPTCHA").tag("challenge")
                        Text("Allow").tag("whitelist")
                    }
                }
                
                Section(header: Text("Notes (Optional)")) {
                    TextField("Reason for this rule", text: $notes)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .focused($focusedField, equals: .notes)
                        .onSubmit { focusedField = nil }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        HapticManager.impact(.medium)
                        Task {
                            let success = await viewModel.createRule(
                                zoneId: zoneId,
                                mode: mode,
                                target: target,
                                value: value,
                                notes: notes
                            )
                            if success {
                                isPresented = false
                            }
                        }
                    }
                    .disabled(value.isEmpty || viewModel.isCreating)
                }
            }
        }
    }
}
