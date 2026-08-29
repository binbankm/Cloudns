import SwiftUI

struct EmailRoutingView: View {
    let zoneId: String
    let zoneName: String
    
    @StateObject private var viewModel: EmailRoutingViewModel
    @State private var showingAddRuleSheet = false
    @State private var showingAddDestinationSheet = false
    @State private var searchText = ""
    
    init(zoneId: String, zoneName: String = "") {
        self.zoneId = zoneId
        self.zoneName = zoneName
        _viewModel = StateObject(wrappedValue: EmailRoutingViewModel(zoneId: zoneId))
    }
    
    private var displayedRules: [EmailRoutingRule] {
        if searchText.isEmpty { return viewModel.rules }
        return viewModel.rules.filter {
            ($0.name ?? "").localizedStandardContains(searchText) ||
            ($0.matchAddress ?? "").localizedStandardContains(searchText) ||
            ($0.forwardTo ?? "").localizedStandardContains(searchText)
        }
    }
    
    var body: some View {
        List {
            // MARK: - Master Toggle
            Section(
                header: Text("Status"),
                footer: Text("When enabled, Cloudflare receives incoming emails for your domain and forwards them according to your routing rules.")
            ) {
                Toggle(isOn: Binding(
                    get: { viewModel.settings?.isEnabled ?? false },
                    set: { enabled in
                        Task { await viewModel.toggleEnabled(enabled) }
                    }
                )) {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.badge.fill")
                            .foregroundStyle(.orange)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Email Routing")
                                .font(.body.weight(.medium))
                            if let status = viewModel.settings?.status {
                                Text("Status: \(status.capitalized)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .disabled(!viewModel.hasFetchedData)
            }
            
            // MARK: - Catch-all Rule
            Section(
                header: Text("Catch-All Rule"),
                footer: Text("Action for emails sent to addresses on this domain that do not match any explicit routing rule.")
            ) {
                Toggle(isOn: Binding(
                    get: { viewModel.catchAllRule?.isEnabled ?? false },
                    set: { enabled in
                        Task { await viewModel.toggleCatchAll(enabled: enabled) }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Catch-all Email")
                            .font(.body)
                        Text(viewModel.catchAllRule?.actionSummary ?? "Drop all unmatched emails")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!viewModel.hasFetchedData)
            }
            
            // MARK: - Routing Rules
            Section(
                header: HStack {
                    Text("Custom Routing Rules")
                    Spacer()
                    Button {
                        showingAddRuleSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption.bold())
                    }
                    .accessibilityLabel("Add Email Rule")
                },
                footer: Text(viewModel.verifiedDestinations.isEmpty ? "To create forwarding rules, you must first add and verify at least one destination address below." : "Forward custom domain addresses to your verified email inboxes.")
            ) {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    ForEach(EmailRoutingRule.placeholders) { placeholderRule in
                        ruleRow(placeholderRule)
                    }
                    .redacted(reason: .placeholder)
                } else if displayedRules.isEmpty {
                    Text("No custom routing rules configured.")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(displayedRules) { rule in
                        ruleRow(rule)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HIGFeedback.impact(.medium)
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
            
            // MARK: - Destination Addresses
            Section(
                header: HStack {
                    Text("Destination Addresses (\(viewModel.destinations.count))")
                    Spacer()
                    Button {
                        showingAddDestinationSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption.bold())
                    }
                    .accessibilityLabel("Add Destination Address")
                },
                footer: Text("Cloudflare sends a verification link to newly added destination inboxes before emails can be routed to them.")
            ) {
                if viewModel.destinations.isEmpty {
                    Text("No destination addresses configured.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(viewModel.destinations) { dest in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dest.email)
                                    .font(.body)
                                if let created = dest.created {
                                    Text("Added: \(created.prefix(10))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if dest.isVerified {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(.green)
                                    Text("Verified")
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                }
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.badge.exclamationmark")
                                        .foregroundStyle(.orange)
                                    Text("Pending")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                Task {
                                    await viewModel.deleteDestination(addressId: dest.id)
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
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search Email Rules"
        )
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty && viewModel.destinations.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchData() }
                            }
                        )
                    )
                } else if viewModel.rules.isEmpty && viewModel.destinations.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Email Routing Rules",
                            systemImage: "envelope.badge.shield.half.filled",
                            description: "Create custom email addresses and forward incoming mail to your personal inboxes.",
                            actionTitle: "Add Rule",
                            action: { showingAddRuleSheet = true }
                        )
                    )
                } else if !searchText.isEmpty && displayedRules.isEmpty {
                    HIGContentState(.search(query: searchText))
                }
            }
        }
        .navigationTitle("Email Routing")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddRuleSheet) {
            AddEmailRuleView(viewModel: viewModel, zoneName: zoneName)
        }
        .sheet(isPresented: $showingAddDestinationSheet) {
            AddDestinationAddressSheetView(viewModel: viewModel)
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

// MARK: - AddDestinationAddressSheetView (Inlined & Cohesive)

struct AddDestinationAddressSheetView: View {
    @ObservedObject var viewModel: EmailRoutingViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var isSubmitting = false
    @FocusState private var isFocused: Bool
    
    var isValidEmail: Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("Destination Email"),
                    footer: Text("Cloudflare will send a verification email with an activation link to this address. You must verify it before forwarding emails to it.")
                ) {
                    TextField("name@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            if isValidEmail && !isSubmitting {
                                submit()
                            }
                        }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Destination")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        submit()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Send Verification")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isValidEmail || isSubmitting)
                }
            }
            .interactiveDismissDisabled(isSubmitting)
            .onAppear { isFocused = true }
        }
    }
    
    private func submit() {
        let target = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return }
        
        isSubmitting = true
        Task {
            let success = await viewModel.addDestination(email: target)
            isSubmitting = false
            if success {
                HIGFeedback.success()
                dismiss()
            } else {
                HIGFeedback.error()
            }
        }
    }
}
