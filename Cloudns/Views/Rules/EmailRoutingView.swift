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
            VStack(spacing: 12) {
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
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.orange)
                }
                .padding(.top, 4)
                
                Text("Email Routing")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                
                Text("Create custom email addresses and forward them to personal inboxes.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
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
                    HapticManager.selection()
                    Task {
                        await viewModel.toggleEnabled(enabled)
                        ToastManager.shared.showSuccess(enabled ? LocalizedStringKey("Email Routing Enabled") : LocalizedStringKey("Email Routing Disabled"), icon: "envelope.badge.fill")
                    }
                }
            )) {
                HStack(spacing: 12) {
                    ListRowIcon(icon: "envelope.badge.fill", color: .orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Email Routing")
                            .font(.body)
                        Text(statusDescription)
                            .font(.caption)
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
                    HapticManager.selection()
                    Task {
                        await viewModel.toggleCatchAll(enabled: enabled)
                        ToastManager.shared.showSuccess(enabled ? LocalizedStringKey("Catch-all Enabled") : LocalizedStringKey("Catch-all Disabled"), icon: "tray.fill")
                    }
                }
            )) {
                HStack(spacing: 12) {
                    ListRowIcon(icon: "tray.fill", color: .purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Catch-all Email")
                            .font(.body)
                        Text(viewModel.catchAllRule?.actionSummary ?? String(localized: "Drop all unmatched emails"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(!viewModel.hasFetchedData)
        }
    }
    
    private var rulesSection: some View {
        Section {
            if viewModel.rules.isEmpty {
                Text("No custom routing rules configured.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(viewModel.rules) { rule in
                    ruleRow(rule)
                        .contextMenu {
                            if let match = rule.matchAddress {
                                Button {
                                    copyToClipboard(match, toast: "Match Address Copied")
                                } label: {
                                    Label("Copy Address", systemImage: "doc.on.doc")
                                }
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                ruleToDelete = rule
                                showingDeleteAlert = true
                                HapticManager.impact(.medium)
                            } label: {
                                Label("Delete Rule", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                ruleToDelete = rule
                                showingDeleteAlert = true
                                HapticManager.impact(.medium)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        } header: {
            HStack {
                Text("Custom Rules")
                Spacer()
                Button {
                    showingAddRuleSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Email Rule")
                .disabled(viewModel.verifiedDestinations.isEmpty || !viewModel.hasFetchedData)
            }
        } footer: {
            Text(viewModel.verifiedDestinations.isEmpty ? LocalizedStringKey("To create forwarding rules, you must first add and verify at least one destination address below.") : LocalizedStringKey("Forward custom domain addresses to your verified email inboxes."))
        }
    }
    
    private var destinationsSection: some View {
        Section {
            if viewModel.destinations.isEmpty {
                Text("No destination addresses added.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(viewModel.destinations) { dest in
                    destinationRow(dest)
                        .contextMenu {
                            Button {
                                copyToClipboard(dest.email, toast: "Destination Email Copied")
                            } label: {
                                Label("Copy Email", systemImage: "doc.on.doc")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
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
                                HapticManager.impact(.medium)
                                Task {
                                    await viewModel.deleteDestination(addressId: dest.id)
                                    ToastManager.shared.showSuccess("Destination Deleted", icon: "trash.fill")
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        } header: {
            HStack {
                Text("Destination Addresses")
                Spacer()
                Button {
                    showingAddDestinationSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Destination Address")
                .disabled(!viewModel.hasFetchedData)
            }
        } footer: {
            Text("Destination addresses must be verified via confirmation email before rules can forward to them.")
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
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Email Routing…",
            error: (viewModel.rules.isEmpty && viewModel.destinations.isEmpty) ? viewModel.errorMessage : nil,
            onRetry: {
                Task { await viewModel.fetchData() }
            }
        )
        .navigationTitle("Email Routing")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddRuleSheet) {
            AddEmailRuleView(viewModel: viewModel, zoneName: zoneName)
        }
        .sheet(isPresented: $showingAddDestinationSheet) {
            AddDestinationAddressSheetView(viewModel: viewModel)
        }
        .confirmationDialog("Delete Email Rule", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: ruleToDelete) { rule in
            let ruleName = (rule.name?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { s in s.isEmpty ? nil : s } ?? (rule.matchAddress?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { s in s.isEmpty ? nil : s } ?? String(localized: "Rule")
            Button("Delete '\(ruleName)'", role: .destructive) {
                Task {
                    await viewModel.deleteRule(ruleId: rule.id)
                    ToastManager.shared.showSuccess("Email Rule Deleted", icon: "trash.fill")
                    HapticManager.notification(.success)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { rule in
            let ruleName = (rule.name?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { s in s.isEmpty ? nil : s } ?? (rule.matchAddress?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { s in s.isEmpty ? nil : s } ?? String(localized: "Rule")
            Text("Are you sure you want to delete email rule '\(ruleName)'?")
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
        HStack(spacing: 12) {
            ListRowIcon(icon: "arrow.triangle.branch", color: rule.isEnabled ? .blue : .gray)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    if let match = rule.matchAddress {
                        Text(match)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                    } else if rule.isCatchAll {
                        Text("Catch-all")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                    } else if let name = rule.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(name)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                    } else {
                        Text("Rule")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                    }
                }
                HStack(spacing: 4) {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(rule.actionSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            
            Text(rule.isEnabled ? LocalizedStringKey("Active") : LocalizedStringKey("Disabled"))
                .font(.caption2.weight(.medium))
                .foregroundStyle(rule.isEnabled ? Color.green : Color.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill((rule.isEnabled ? Color.green : Color.secondary).opacity(0.12)))
        }
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    private func destinationRow(_ dest: EmailDestinationAddress) -> some View {
        HStack(spacing: 12) {
            ListRowIcon(icon: "envelope.fill", color: dest.isVerified ? .blue : .orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: dest.email)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(dest.isVerified ? LocalizedStringKey("Verified") : LocalizedStringKey("Pending Verification"))
                    .font(.caption)
                    .foregroundStyle(dest.isVerified ? Color.secondary : Color.orange)
            }
            Spacer()
            
            Text(dest.isVerified ? LocalizedStringKey("Verified") : LocalizedStringKey("Pending"))
                .font(.caption2.weight(.medium))
                .foregroundStyle(dest.isVerified ? Color.green : Color.orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill((dest.isVerified ? Color.green : Color.orange).opacity(0.12)))
        }
        .padding(.vertical, 2)
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
                        .font(.body)
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
                HapticManager.notification(.success)
                ToastManager.shared.showSuccess("Verification Email Sent", icon: "paperplane.fill")
                dismiss()
            } else {
                HapticManager.notification(.error)
            }
        }
    }
}
