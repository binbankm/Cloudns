import SwiftUI

// MARK: - WAFCustomRulesView

// Apple HIG Compliant Cloudflare Web Application Firewall Custom Rule Engine

struct WAFCustomRulesView: View {
    let zoneId: String
    var zoneName: String = ""
    var zoneTier: PlanTier = .free

    @StateObject private var viewModel = WAFViewModel()
    @State private var showingAddSheet = false
    @State private var showingUpgradeSheet = false
    @State private var ruleToDelete: WAFRule?
    @State private var showingDeleteConfirm = false

    private var maxAllowedRules: Int {
        switch zoneTier {
        case .free: 5
        case .pro: 20
        case .business: 100
        case .enterprise: 1000
        default: 5
        }
    }

    private var isQuotaExceeded: Bool {
        viewModel.rules.count >= maxAllowedRules
    }

    private var sectionHeaderView: some View {
        HStack {
            Text("Custom Rules (\(viewModel.rules.count)/\(maxAllowedRules))")
            Spacer()
            if zoneTier == .free {
                Text("Free: 5 max")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var sectionFooterView: some View {
        if isQuotaExceeded && zoneTier == .free {
            HStack {
                Text("Rule quota reached (5/5). Upgrade to Pro for 20 custom rules.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Upgrade") {
                    showingUpgradeSheet = true
                }
                .font(.caption.weight(.semibold))
            }
        } else {
            Text("Custom firewall rules inspect incoming traffic and enforce security actions.")
        }
    }

    var body: some View {
        List {
            if !viewModel.rules.isEmpty {
                Section(header: sectionHeaderView, footer: sectionFooterView) {
                    ForEach(viewModel.rules) { rule in
                        WAFRuleCardView(rule: rule, onToggle: {
                            HapticManager.selection()
                            Task {
                                await viewModel.toggleRule(zoneId: zoneId, rule: rule)
                                ToastManager.shared.showSuccess(rule.enabled ? LocalizedStringKey("WAF Rule Disabled") : LocalizedStringKey("WAF Rule Enabled"), icon: "shield.lefthalf.filled")
                            }
                        })
                        .contextMenu {
                            Button {
                                copyToClipboard(rule.expression, toast: "Rule Expression Copied")
                            } label: {
                                Label("Copy Expression", systemImage: "doc.on.doc")
                            }

                            if let desc = rule.description {
                                Button {
                                    copyToClipboard(desc, toast: "Rule Name Copied")
                                } label: {
                                    Label("Copy Rule Name", systemImage: "tag")
                                }
                            }

                            Divider()

                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                ruleToDelete = rule
                                showingDeleteConfirm = true
                            } label: {
                                Label("Delete Rule", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                ruleToDelete = rule
                                showingDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
            }

            // MARK: - Managed Rulesets (OWASP)
            Section {
                if zoneTier == .free {
                    Button {
                        HapticManager.notification(.warning)
                        showingUpgradeSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            ListRowIcon(icon: "shield.checkered", color: .orange)
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text("Cloudflare & OWASP Rulesets")
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    PlanBadgeView(
                                        title: PlanTier.pro.shortBadge,
                                        tintColor: PlanBadgeView.color(for: .pro),
                                        isUnlocked: false
                                    )
                                }
                                Text("Pre-configured enterprise rules protecting against OWASP Top 10, SQLi, and zero-day vulnerabilities.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    managedRulesetRow(
                        title: "Cloudflare Managed Ruleset",
                        subtitle: "Zero-day vulnerability & exploit defense curated by Cloudflare Security",
                        action: "Block",
                        sensitivity: "High"
                    )
                    managedRulesetRow(
                        title: "OWASP ModSecurity Core Rule Set",
                        subtitle: "Protection against SQLi, XSS, and remote code execution",
                        action: "Block",
                        sensitivity: "Paranoia L1"
                    )
                }
            } header: {
                Text("Managed Rulesets")
            } footer: {
                Text(zoneTier == .free
                    ? "WAF Managed Rulesets require a Cloudflare Pro or higher plan."
                    : "Automated security rules maintained by Cloudflare and updated in real-time.")
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.fetchWAFRules(zoneId: zoneId)
        }
        .navigationTitle("WAF Custom Rules")
        .navigationBarTitleDisplayMode(.inline)
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading WAF Rules…",
            error: viewModel.rules.isEmpty ? viewModel.errorMessage : nil,
            isEmpty: viewModel.hasFetchedData && viewModel.rules.isEmpty,
            empty: EmptyStateConfig(
                title: "No WAF Custom Rules",
                systemImage: "shield.slash",
                description: "Create custom firewall rules to protect your web application from malicious traffic.",
                actionTitle: "Add WAF Rule",
                action: { showingAddSheet = true }
            ),
            onRetry: { Task { await viewModel.fetchWAFRules(zoneId: zoneId) } }
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
        .sheet(isPresented: $showingUpgradeSheet) {
            PlanUpgradeSheetView(
                featureName: "WAF Custom Rules Quota",
                currentTier: zoneTier,
                requiredTier: .pro,
                zoneName: zoneName
            )
        }
        .confirmationDialog(
            "Delete WAF Rule",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            if let rule = ruleToDelete {
                Button("Delete Rule", role: .destructive) {
                    Task {
                        await viewModel.deleteRule(zoneId: zoneId, ruleId: rule.id)
                        ToastManager.shared.showSuccess("WAF Rule Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                        ruleToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                ruleToDelete = nil
            }
        } message: {
            if let rule = ruleToDelete {
                let ruleName = (rule.description?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { s in s.isEmpty ? nil : s } ?? String(localized: "Untitled Rule")
                Text("Are you sure you want to delete WAF rule '\(ruleName)'?")
            }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchWAFRules(zoneId: zoneId)
            }
        }
    }

    private func managedRulesetRow(title: String, subtitle: String, action: String, sensitivity: String) -> some View {
        HStack(spacing: 12) {
            ListRowIcon(icon: "shield.lefthalf.filled", color: .green)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Text("Action: \(action)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.red.opacity(0.12)))

                    Text("Sensitivity: \(sensitivity)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color(.tertiarySystemFill)))
                }
                .padding(.top, 2)
            }

            Spacer()

            Text("Active")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.green)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.green.opacity(0.12)))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - WAFRuleCardView

struct WAFRuleCardView: View {
    let rule: WAFRule
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let desc = rule.description, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(desc)
                        .font(.body.weight(.medium))
                        .lineLimit(2)
                } else {
                    Text("Untitled Rule")
                        .font(.body.weight(.medium))
                        .lineLimit(2)
                }

                Spacer()

                Toggle(isOn: Binding(
                    get: { rule.enabled },
                    set: { _ in onToggle() }
                )) {
                    Text(rule.description ?? "Unnamed Rule")
                }
                .labelsHidden()
                .accessibilityLabel(rule.description ?? "Unnamed Rule")
            }

            HStack {
                let actionColor = colorForAction(rule.action)
                actionBadge(rule.action)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(actionColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(actionColor.opacity(0.12)))

                Spacer()

                Text(rule.enabled ? LocalizedStringKey("Active") : LocalizedStringKey("Disabled"))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(rule.enabled ? Color.green : Color.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(rule.enabled ? Color.green.opacity(0.12) : Color(.tertiarySystemFill)))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Expression")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(verbatim: rule.expression)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.primary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func actionBadge(_ action: String) -> some View {
        switch action.lowercased() {
        case "block": Text("Block")
        case "managed_challenge": Text("Managed Challenge")
        case "js_challenge": Text("JS Challenge")
        case "challenge": Text("Interactive Challenge")
        case "log": Text("Log")
        case "skip": Text("Skip")
        default: Text(action.capitalized)
        }
    }

    private func colorForAction(_ action: String) -> Color {
        switch action.lowercased() {
        case "block": .red
        case "managed_challenge", "js_challenge", "challenge": .orange
        case "log": .blue
        case "skip": .green
        default: .secondary
        }
    }
}
