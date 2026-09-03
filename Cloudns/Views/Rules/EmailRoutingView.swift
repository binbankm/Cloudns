import SwiftUI

// MARK: - EmailRoutingView
// Apple HIG Compliant Cloudflare Email Routing & Address Forwarding Hub

struct EmailRoutingView: View {
    let zoneId: String
    let zoneName: String
    
    @StateObject private var viewModel: EmailRoutingViewModel
    @State private var showingAddRuleSheet = false
    @State private var showingAddDestinationSheet = false
    @State private var ruleToDelete: EmailRoutingRule?
    @State private var showingDeleteAlert = false
    
    init(zoneId: String, zoneName: String = "") {
        self.zoneId = zoneId
        self.zoneName = zoneName
        _viewModel = StateObject(wrappedValue: EmailRoutingViewModel(zoneId: zoneId))
    }
    
    private var statusDescription: String {
        if let status = viewModel.settings?.status {
            return status.capitalized
        }
        return "Configuring"
    }
    
    private var heroHeaderSection: some View {
        Section {
            VStack(spacing: HIGTokens.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.18), Color.yellow.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "envelope.badge.shield.half.filled")
                        .font(HIGTypography.title2.weight(.semibold))
                        .foregroundStyle(.orange)
                }
                .padding(.top, HIGTokens.Spacing.xs)
                
                Text("Email Routing")
                    .font(HIGTypography.title2.weight(.bold))
                    .foregroundStyle(.primary)
                
                Text("Create custom email addresses and forward them to personal inboxes.")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HIGTokens.Spacing.md)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, HIGTokens.Spacing.sm)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
    
    private var statusSection: some View {
        Section(
            header: Text("Status"),
            footer: Text("When enabled, Cloudflare receives incoming emails for your domain and forwards them according to your routing rules.")
        ) {
            Toggle(isOn: Binding(
                get: { viewModel.settings?.isEnabled ?? false },
                set: { enabled in
                    HIGFeedback.selection()
                    Task {
                        await viewModel.toggleEnabled(enabled)
                        ToastManager.shared.showSuccess(enabled ? "Email Routing Enabled" : "Email Routing Disabled", icon: "envelope.badge.fill")
                    }
                }
            )) {
                HStack(spacing: HIGTokens.Spacing.md) {
                    ListRowIcon(icon: "envelope.badge.fill", color: .orange)
                    VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                        Text("Email Routing")
                            .font(HIGTypography.body)
                        Text(statusDescription)
                            .font(HIGTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(!viewModel.hasFetchedData)
        }
    }
    
    private var catchAllSection: some View {
        Section(
            header: Text("Catch-All Rule"),
            footer: Text("Action for emails sent to addresses on this domain that do not match any explicit routing rule.")
        ) {
            Toggle(isOn: Binding(
                get: { viewModel.catchAllRule?.isEnabled ?? false },
                set: { enabled in
                    HIGFeedback.selection()
                    Task {
                        await viewModel.toggleCatchAll(enabled: enabled)
                        ToastManager.shared.showSuccess(enabled ? "Catch-all Enabled" : "Catch-all Disabled", icon: "tray.fill")
                    }
                }
            )) {
                HStack(spacing: HIGTokens.Spacing.md) {
                    ListRowIcon(icon: "tray.fill", color: .purple)
                    VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                        Text("Catch-all Email")
                            .font(HIGTypography.body)
                        Text(viewModel.catchAllRule?.actionSummary ?? "Drop all unmatched emails")
                            .font(HIGTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(!viewModel.hasFetchedData)
        }
    }
    
    private var rulesSection: some View {
        Section(
            header: HStack {
                Text("Custom Rules")
                Spacer()
                Button {
                    showingAddRuleSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Email Rule")
                .disabled(viewModel.verifiedDestinations.isEmpty || !viewModel.hasFetchedData)
                .higTouchTarget(44)
            },
            footer: Text(viewModel.verifiedDestinations.isEmpty ? "To create forwarding rules, you must first add and verify at least one destination address below." : "Forward custom domain addresses to your verified email inboxes.")
        ) {
            if viewModel.rules.isEmpty {
                Text("No custom routing rules configured.")
                    .font(HIGTypography.body)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, HIGTokens.Spacing.xs)
            } else {
                ForEach(viewModel.rules) { rule in
                    ruleRow(rule)
                        .contextMenu {
                            if let match = rule.matchAddress {
                                Button {
                                    UIPasteboard.general.string = match
                                    ToastManager.shared.showCopied("Match Address Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy Address", systemImage: "doc.on.doc")
                                }
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                ruleToDelete = rule
                                showingDeleteAlert = true
                                HIGFeedback.impact(.medium)
                            } label: {
                                Label("Delete Rule", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                ruleToDelete = rule
                                showingDeleteAlert = true
                                HIGFeedback.impact(.medium)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(HIGColors.error)
                        }
                }
            }
        }
    }
    
    private var destinationsSection: some View {
        Section(
            header: HStack {
                Text("Destination Addresses")
                Spacer()
                Button {
                    showingAddDestinationSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Destination Address")
                .disabled(!viewModel.hasFetchedData)
                .higTouchTarget(44)
            },
            footer: Text("Destination addresses must be verified via confirmation email before rules can forward to them.")
        ) {
            if viewModel.destinations.isEmpty {
                Text("No destination addresses added.")
                    .font(HIGTypography.body)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, HIGTokens.Spacing.xs)
            } else {
                ForEach(viewModel.destinations) { dest in
                    destinationRow(dest)
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = dest.email
                                ToastManager.shared.showCopied("Destination Email Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy Email", systemImage: "doc.on.doc")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                Task {
                                    await viewModel.deleteDestination(addressId: dest.id)
                                    ToastManager.shared.showSuccess("Destination Deleted", icon: "trash.fill")
                                }
                            } label: {
                                Label("Delete Destination", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                Task {
                                    await viewModel.deleteDestination(addressId: dest.id)
                                    ToastManager.shared.showSuccess("Destination Deleted", icon: "trash.fill")
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(HIGColors.error)
                        }
                }
            }
        }
    }
    
    var body: some View {
        List {
            heroHeaderSection
            statusSection
            catchAllSection
            rulesSection
            destinationsSection
        }
        .listStyle(.insetGrouped)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Email Routing…"))
            } else if let errorMessage = viewModel.errorMessage, viewModel.rules.isEmpty && viewModel.destinations.isEmpty {
                HIGContentState(
                    .error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task { await viewModel.fetchData() }
                        }
                    )
                )
            }
        }
        .navigationTitle("Email Routing")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddRuleSheet) {
            AddEmailRuleView(viewModel: viewModel, zoneName: zoneName)
                .higToast()
        }
        .sheet(isPresented: $showingAddDestinationSheet) {
            AddDestinationAddressSheetView(viewModel: viewModel)
                .higToast()
        }
        .confirmationDialog("Delete Email Rule", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: ruleToDelete) { rule in
            Button("Delete '\(rule.name ?? "Rule")'", role: .destructive) {
                Task {
                    await viewModel.deleteRule(ruleId: rule.id)
                    ToastManager.shared.showSuccess("Email Rule Deleted", icon: "trash.fill")
                    HIGFeedback.success()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { rule in
            Text("Are you sure you want to delete email rule '\(rule.name ?? rule.matchAddress ?? "Rule")'?")
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
        HStack(spacing: HIGTokens.Spacing.md) {
            ListRowIcon(icon: "arrow.triangle.branch", color: rule.isEnabled ? .blue : .gray)
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                HStack {
                    if let match = rule.matchAddress {
                        Text(match)
                            .font(HIGTypography.body.weight(.medium))
                            .foregroundStyle(.primary)
                    } else if rule.isCatchAll {
                        Text("Catch-all")
                            .font(HIGTypography.body.weight(.medium))
                            .foregroundStyle(.primary)
                    } else {
                        Text(rule.name ?? "Rule")
                            .font(HIGTypography.body.weight(.medium))
                            .foregroundStyle(.primary)
                    }
                }
                HStack(spacing: HIGTokens.Spacing.xs) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(HIGTypography.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(rule.actionSummary)
                        .font(HIGTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if rule.isEnabled {
                HIGBadge(.active, isCompact: true)
            } else {
                HIGBadge(.custom(color: .secondary, text: "Disabled"), isCompact: true)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
    }
    
    @ViewBuilder
    private func destinationRow(_ dest: EmailDestinationAddress) -> some View {
        HStack(spacing: HIGTokens.Spacing.md) {
            ListRowIcon(icon: "envelope.fill", color: dest.isVerified ? .blue : .orange)
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text(verbatim: dest.email)
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(dest.isVerified ? "Verified" : "Pending Verification")
                    .font(HIGTypography.caption)
                    .foregroundStyle(dest.isVerified ? Color.secondary : Color.orange)
            }
            Spacer()
            if dest.isVerified {
                HIGBadge(.active("Verified"), isCompact: true)
            } else {
                HIGBadge(.warning("Pending"), isCompact: true)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
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
                        .font(HIGTypography.body)
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
                        .higTouchTarget(44)
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
                    .higTouchTarget(44)
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
                ToastManager.shared.showSuccess("Verification Email Sent", icon: "paperplane.fill")
                dismiss()
            } else {
                HIGFeedback.error()
            }
        }
    }
}
