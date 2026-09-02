import SwiftUI

// MARK: - IPAccessRulesView
// Apple HIG Compliant IP Access Rules Management

struct IPAccessRulesView: View {
    let zoneId: String
    
    @StateObject private var viewModel = IPAccessRulesViewModel()
    @State private var showingAddRule = false
    @State private var ruleToDelete: IPAccessRule?
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        List {
            if !viewModel.rules.isEmpty {
                Section {
                    ForEach(viewModel.rules) { rule in
                        IPAccessRuleRowView(rule: rule)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = rule.configuration.value
                                    ToastManager.shared.showCopied("Target Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy Target", systemImage: "doc.on.doc")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    ruleToDelete = rule
                                    showingDeleteConfirm = true
                                } label: {
                                    Label("Delete Rule", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    ruleToDelete = rule
                                    showingDeleteConfirm = true
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
        .refreshable {
            await viewModel.fetchRules(zoneId: zoneId)
        }
        .navigationTitle("IP Access Rules")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading IP Access Rules…"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty {
                HIGContentState(
                    .error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task { await viewModel.fetchRules(zoneId: zoneId) }
                        }
                    )
                )
            } else if viewModel.hasFetchedData && viewModel.rules.isEmpty {
                HIGContentState(
                    .empty(
                        title: "No IP Access Rules",
                        systemImage: "network.badge.shield.half.filled",
                        description: "You haven't created any IP access rules yet. Add a rule to block or challenge specific IPs or countries.",
                        actionTitle: "Add IP Rule",
                        action: { showingAddRule = true }
                    )
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showingAddRule = true
                }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add IP Rule")
                .higTouchTarget()
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingAddRule) {
            AddIPAccessRuleView(zoneId: zoneId, viewModel: viewModel, isPresented: $showingAddRule)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .higToast()
        }
        .confirmationDialog(
            "Delete IP Access Rule",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            if let rule = ruleToDelete {
                Button("Delete Rule", role: .destructive) {
                    Task {
                        await viewModel.deleteRule(zoneId: zoneId, ruleId: rule.id)
                        ToastManager.shared.showSuccess("IP Rule Deleted", icon: "trash.fill")
                        HIGFeedback.success()
                        ruleToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                ruleToDelete = nil
            }
        } message: {
            if let rule = ruleToDelete {
                Text("Are you sure you want to delete the \(rule.mode.uppercased()) rule for \(rule.configuration.value)?")
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchRules(zoneId: zoneId)
            }
        }
    }
}

// MARK: - IPAccessRuleRowView (Inlined & Cohesive)

struct IPAccessRuleRowView: View {
    let rule: IPAccessRule
    
    var body: some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
            HStack {
                Text(rule.configuration.value)
                    .font(HIGTypography.body.monospacedDigit().weight(.medium))
                
                Spacer()
                
                HIGBadge(.custom(color: colorForMode(rule.mode), text: rule.mode.uppercased()), isCompact: true)
            }
            
            HStack(spacing: HIGTokens.Spacing.xs) {
                Text(rule.configuration.target.uppercased().replacingOccurrences(of: "_", with: " "))
                    .font(HIGTypography.caption)
                    .foregroundStyle(.secondary)
                
                if let notes = rule.notes, !notes.isEmpty {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(notes)
                        .font(HIGTypography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
    
    private func colorForMode(_ mode: String) -> Color {
        switch mode {
        case "block": return HIGColors.error
        case "challenge", "js_challenge", "managed_challenge": return HIGColors.warning
        case "whitelist": return HIGColors.success
        default: return .blue
        }
    }
}

// MARK: - AddIPAccessRuleView (Inlined & Cohesive)

struct AddIPAccessRuleView: View {
    let zoneId: String
    @ObservedObject var viewModel: IPAccessRulesViewModel
    @Binding var isPresented: Bool
    
    @State private var target = "ip"
    @State private var value = ""
    @State private var mode = "block"
    @State private var notes = ""
    @State private var showingDiscardAlert = false
    
    enum Field { case value, notes }
    @FocusState private var focusedField: Field?
    
    private var hasChanges: Bool {
        !value.isEmpty || !notes.isEmpty
    }
    
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
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges {
                            showingDiscardAlert = true
                        } else {
                            isPresented = false
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        HIGFeedback.impact(.medium)
                        Task {
                            let success = await viewModel.createRule(
                                zoneId: zoneId,
                                mode: mode,
                                target: target,
                                value: value,
                                notes: notes
                            )
                            if success {
                                ToastManager.shared.showSuccess("IP Rule Added", icon: "network.badge.shield.half.filled")
                                isPresented = false
                            }
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(value.isEmpty || viewModel.isCreating)
                }
            }
            .interactiveDismissDisabled(hasChanges && !viewModel.isCreating)
            .confirmationDialog("Discard Rule?", isPresented: $showingDiscardAlert, titleVisibility: .visible) {
                Button("Discard", role: .destructive) { isPresented = false }
                Button("Keep Editing", role: .cancel) { }
            }
        }
    }
}
