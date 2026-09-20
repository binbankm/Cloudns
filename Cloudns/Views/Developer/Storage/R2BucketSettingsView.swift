import SwiftUI

// MARK: - R2BucketSettingsView

// Apple HIG Compliant Cloudflare R2 Bucket Configuration, Managed Domains & CORS Rules

struct R2BucketSettingsView: View {
    let accountId: String
    let bucketName: String
    @StateObject private var viewModel: R2BucketSettingsViewModel
    @State private var showingAddCORSSheet = false
    @State private var showingAddLifecycleSheet = false
    @State private var showingAddNotificationSheet = false
    @State private var domainToDelete: R2CustomDomain?
    @State private var corsIndexToDelete: Int?
    @State private var lifecycleRuleToDelete: R2LifecycleRule?
    @State private var notificationToDelete: R2EventNotificationConfig?
    @State private var showingDeleteDomainConfirm = false
    @State private var showingDeleteCORSConfirm = false
    @State private var showingDeleteLifecycleConfirm = false
    @State private var showingDeleteNotificationConfirm = false

    init(accountId: String, bucketName: String) {
        self.accountId = accountId
        self.bucketName = bucketName
        _viewModel = StateObject(wrappedValue: R2BucketSettingsViewModel(accountId: accountId, bucketName: bucketName))
    }

    var body: some View {
        List {
            if viewModel.hasFetchedData {
                // MARK: - r2.dev Managed Domain

                Section {
                    Toggle("Enable r2.dev Subdomain", isOn: Binding(
                        get: { viewModel.isManagedDomainEnabled },
                        set: { newValue in
                            Task { await viewModel.toggleManagedDomain(enabled: newValue) }
                        }
                    ))

                    if viewModel.isManagedDomainEnabled, let domain = viewModel.managedDomain?.domain {
                        HStack {
                            Text("Public URL")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("https://\(domain)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.blue)
                        }
                    }
                } header: {
                    Text("Public Access (r2.dev)")
                } footer: {
                    Text("Allows public read access to objects in this bucket using a Cloudflare-managed r2.dev subdomain.")
                }

                // MARK: - Custom Domains

                Section {
                    if viewModel.customDomains.isEmpty {
                        Text("No custom domains connected.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.customDomains) { domain in
                            customDomainRow(domain)
                                .contextMenu {
                                    Button {
                                        copyToClipboard(domain.domain, toast: "Domain Copied")
                                    } label: {
                                        Label("Copy Domain", systemImage: "doc.on.doc")
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        domainToDelete = domain
                                        showingDeleteDomainConfirm = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete Custom Domain", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        domainToDelete = domain
                                        showingDeleteDomainConfirm = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                } header: {
                    Text("Connected Custom Domains (\(viewModel.customDomains.count))")
                } footer: {
                    Text("Custom domains configured for public bucket access.")
                }

                // MARK: - CORS Rules

                Section {
                    if viewModel.corsRules.isEmpty {
                        Text("No CORS rules configured.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(viewModel.corsRules.enumerated()), id: \.offset) { index, rule in
                            corsRuleRow(rule)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        corsIndexToDelete = index
                                        showingDeleteCORSConfirm = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete CORS Rule", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        corsIndexToDelete = index
                                        showingDeleteCORSConfirm = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                } header: {
                    HStack {
                        Text("CORS Rules (\(viewModel.corsRules.count))")
                        Spacer()
                        Button {
                            showingAddCORSSheet = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.subheadline)
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    Text("Cross-Origin Resource Sharing rules for browser requests.")
                }

                // MARK: - Object Lifecycle Rules

                Section {
                    if viewModel.lifecycleRules.isEmpty {
                        Text("No lifecycle rules configured.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.lifecycleRules) { rule in
                            lifecycleRuleRow(rule)
                                .contextMenu {
                                    Button {
                                        copyToClipboard(rule.id, toast: "Rule ID Copied")
                                    } label: {
                                        Label("Copy Rule ID", systemImage: "doc.on.doc")
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        lifecycleRuleToDelete = rule
                                        showingDeleteLifecycleConfirm = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete Lifecycle Rule", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        lifecycleRuleToDelete = rule
                                        showingDeleteLifecycleConfirm = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                } header: {
                    HStack {
                        Text("Lifecycle Rules (\(viewModel.lifecycleRules.count))")
                        Spacer()
                        Button {
                            showingAddLifecycleSheet = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.subheadline)
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    Text("Manage automatic object expiration and transitions to colder storage tiers.")
                }

                // MARK: - Event Notifications

                Section {
                    if viewModel.eventNotifications.isEmpty {
                        Text("No event notifications configured.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.eventNotifications, id: \.queueId) { notif in
                            eventNotificationRow(notif)
                                .contextMenu {
                                    if let q = notif.queueId ?? notif.queue {
                                        Button {
                                            copyToClipboard(q, toast: "Queue ID Copied")
                                        } label: {
                                            Label("Copy Queue ID", systemImage: "doc.on.doc")
                                        }
                                    }

                                    Divider()

                                    Button(role: .destructive) {
                                        notificationToDelete = notif
                                        showingDeleteNotificationConfirm = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete Notification", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        notificationToDelete = notif
                                        showingDeleteNotificationConfirm = true
                                        HapticManager.impact(.medium)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                } header: {
                    HStack {
                        Text("Event Notifications (\(viewModel.eventNotifications.count))")
                        Spacer()
                        Button {
                            showingAddNotificationSheet = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.subheadline)
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    Text("Send real-time notifications to Cloudflare Queues on bucket object mutations.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Bucket Settings…"
        )
        .navigationTitle("Bucket Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddCORSSheet) {
            AddCORSRuleSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddLifecycleSheet) {
            AddR2LifecycleRuleSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddNotificationSheet) {
            AddR2EventNotificationSheetView(viewModel: viewModel)
        }
        .confirmationDialog("Delete Custom Domain", isPresented: $showingDeleteDomainConfirm, titleVisibility: .visible) {
            if let domain = domainToDelete {
                Button("Delete '\(domain.domain)'", role: .destructive) {
                    Task {
                        await viewModel.deleteCustomDomain(domain: domain.domain)
                        ToastManager.shared.showSuccess("Custom Domain Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                        domainToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                domainToDelete = nil
            }
        } message: {
            Text("Are you sure you want to disconnect this custom domain?")
        }
        .confirmationDialog("Delete CORS Rule", isPresented: $showingDeleteCORSConfirm, titleVisibility: .visible) {
            if let idx = corsIndexToDelete {
                Button("Delete CORS Rule", role: .destructive) {
                    Task {
                        await viewModel.deleteCORSRule(at: idx)
                        ToastManager.shared.showSuccess("CORS Rule Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                        corsIndexToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                corsIndexToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this CORS rule?")
        }
        .confirmationDialog("Delete Lifecycle Rule", isPresented: $showingDeleteLifecycleConfirm, titleVisibility: .visible) {
            if let rule = lifecycleRuleToDelete {
                Button("Delete '\(rule.id)'", role: .destructive) {
                    Task {
                        await viewModel.deleteLifecycleRule(ruleId: rule.id)
                        ToastManager.shared.showSuccess("Lifecycle Rule Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                        lifecycleRuleToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                lifecycleRuleToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this object lifecycle rule?")
        }
        .confirmationDialog("Delete Notification", isPresented: $showingDeleteNotificationConfirm, titleVisibility: .visible) {
            if let notif = notificationToDelete, let q = notif.queueId ?? notif.queue {
                Button("Delete Notification for '\(q)'", role: .destructive) {
                    Task {
                        await viewModel.deleteEventNotification(queueId: q)
                        ToastManager.shared.showSuccess("Notification Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                        notificationToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                notificationToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this queue event notification config?")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddCORSSheet = true
                    } label: {
                        Label("Add CORS Rule", systemImage: "lock.shield")
                    }

                    Button {
                        showingAddLifecycleSheet = true
                    } label: {
                        Label("Add Lifecycle Rule", systemImage: "clock.arrow.2.circlepath")
                    }

                    Button {
                        showingAddNotificationSheet = true
                    } label: {
                        Label("Add Event Notification", systemImage: "bell.badge")
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Rule or Notification")
            }
        }
        .refreshable {
            await viewModel.fetchSettings()
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchSettings()
            }
        }
    }

    private func customDomainRow(_ domain: R2CustomDomain) -> some View {
        HStack(spacing: 12) {
            ListRowIcon(icon: "globe", color: .blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(domain.domain)
                    .font(.body)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    let isActive = domain.status?.lowercased() == "active"
                    Text((domain.status ?? "Active").capitalized)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(isActive ? .green : .orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill((isActive ? Color.green : Color.orange).opacity(0.12)))

                    if let zone = domain.zoneId {
                        Text("• \(zone)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func lifecycleRuleRow(_ rule: R2LifecycleRule) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(rule.id)
                    .font(.body.weight(.semibold))
                Spacer()
                Text(rule.enabled ? LocalizedStringKey("Enabled") : LocalizedStringKey("Disabled"))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(rule.enabled ? Color.green : Color.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(rule.enabled ? Color.green.opacity(0.12) : Color(.tertiarySystemFill)))
            }

            if let prefix = rule.conditions?.prefix, !prefix.isEmpty {
                HStack(spacing: 4) {
                    Text("Prefix:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(prefix)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.primary)
                }
            }

            if let del = rule.actions?.delete?.maxAgeSeconds {
                HStack(spacing: 4) {
                    Image(systemName: "trash.circle")
                        .font(.caption2)
                        .foregroundStyle(.red)
                    Text("Expire after \(del / 86400) days (\(del)s)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if let abort = rule.actions?.abortMultipartUploads?.maxAgeSeconds {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("Abort incomplete uploads after \(abort / 86400) days")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if let transitions = rule.actions?.storageClassTransitions, !transitions.isEmpty {
                ForEach(Array(transitions.enumerated()), id: \.offset) { _, trans in
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        let days = (trans.condition?.maxAgeSeconds ?? 0) / 86400
                        Text("Transition to \(trans.storageClass ?? "InfrequentAccess") after \(days) days")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func eventNotificationRow(_ notif: R2EventNotificationConfig) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                ListRowIcon(icon: "bell.badge.fill", color: .purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Target Queue")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(notif.queueId ?? notif.queue ?? String(localized: "Unknown Queue"))
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.primary)
                }
            }

            if let rules = notif.rules, !rules.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(rules) { r in
                        HStack(spacing: 6) {
                            ForEach(r.actions, id: \.self) { act in
                                Text(act)
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.purple)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.purple.opacity(0.12)))
                            }

                            if let p = r.prefix, !p.isEmpty {
                                Text("pfx: \(p)")
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            if let s = r.suffix, !s.isEmpty {
                                Text("sfx: \(s)")
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func corsRuleRow(_ rule: R2CORSRule) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Origins: \(rule.allowedOrigins.joined(separator: ", "))")
                    .font(.body.weight(.semibold))
                Spacer()
                if let maxAge = rule.maxAgeSeconds {
                    Text("\(maxAge)s")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Text("Methods: \(rule.allowedMethods.joined(separator: ", "))")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            if let headers = rule.allowedHeaders, !headers.isEmpty {
                Text("Headers: \(headers.joined(separator: ", "))")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - AddCORSRuleSheetView (Inlined & Cohesive)

struct AddCORSRuleSheetView: View {
    @ObservedObject var viewModel: R2BucketSettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var originsText = "*"
    @State private var allowedMethods: Set<String> = ["GET", "HEAD"]
    @State private var maxAgeText = "3600"
    @State private var isSaving = false
    @State private var errorMessage: String?

    let allMethods = ["GET", "PUT", "POST", "DELETE", "HEAD"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://example.com, *", text: $originsText)
                        .font(.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Allowed Origins")
                } footer: {
                    Text("Comma-separated origins (e.g. https://example.com, *).")
                }

                Section("Allowed HTTP Methods") {
                    ForEach(allMethods, id: \.self) { method in
                        Toggle(method, isOn: Binding(
                            get: { allowedMethods.contains(method) },
                            set: { isSelected in
                                if isSelected {
                                    allowedMethods.insert(method)
                                } else {
                                    allowedMethods.remove(method)
                                }
                            }
                        ))
                    }
                }

                Section("Max Age (Seconds)") {
                    TextField("3600", text: $maxAgeText)
                        .font(.body.monospacedDigit())
                        .keyboardType(.numberPad)
                }

                if let err = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(verbatim: err)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add CORS Rule")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            let origins = originsText.components(separatedBy: CharacterSet(charactersIn: ",\n "))
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }
                            let rule = R2CORSRule(
                                allowedOrigins: origins.isEmpty ? ["*"] : origins,
                                allowedMethods: Array(allowedMethods),
                                allowedHeaders: ["*"],
                                maxAgeSeconds: Int(maxAgeText)
                            )
                            let success = await viewModel.saveCORSRule(rule: rule)
                            if success {
                                ToastManager.shared.showSuccess("CORS Rule Saved", icon: "lock.shield.fill")
                                HapticManager.notification(.success)
                                dismiss()
                            } else {
                                ToastManager.shared.showError("Failed to Save CORS Rule")
                                HapticManager.notification(.error)
                            }
                            isSaving = false
                        }
                    }
                    .disabled(allowedMethods.isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}

// MARK: - AddR2LifecycleRuleSheetView

struct AddR2LifecycleRuleSheetView: View {
    @ObservedObject var viewModel: R2BucketSettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var ruleId = ""
    @State private var isEnabled = true
    @State private var prefix = ""
    @State private var enableExpiration = false
    @State private var expireDaysText = "30"
    @State private var enableAbortMultipart = false
    @State private var abortDaysText = "7"
    @State private var enableStorageTransition = false
    @State private var transitionDaysText = "90"
    @State private var targetStorageClass = "InfrequentAccess"
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Rule Identifier") {
                    TextField("e.g. Clean Old Temp Files", text: $ruleId)
                    Toggle("Enable Rule", isOn: $isEnabled)
                }

                Section {
                    TextField("e.g. logs/ or uploads/", text: $prefix)
                        .font(.body.monospaced())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Prefix Filter (Optional)")
                } footer: {
                    Text("Applies rule only to objects matching this key prefix. Leave empty for all objects.")
                }

                Section("Object Expiration") {
                    Toggle("Expire Objects", isOn: $enableExpiration)
                    if enableExpiration {
                        HStack {
                            Text("Expire after (Days)")
                            Spacer()
                            TextField("30", text: $expireDaysText)
                                .font(.body.monospacedDigit())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                    }
                }

                Section("Incomplete Multipart Uploads") {
                    Toggle("Abort Incomplete Uploads", isOn: $enableAbortMultipart)
                    if enableAbortMultipart {
                        HStack {
                            Text("Abort after (Days)")
                            Spacer()
                            TextField("7", text: $abortDaysText)
                                .font(.body.monospacedDigit())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                    }
                }

                Section("Storage Tier Transition") {
                    Toggle("Transition to Cold Storage", isOn: $enableStorageTransition)
                    if enableStorageTransition {
                        HStack {
                            Text("Transition after (Days)")
                            Spacer()
                            TextField("90", text: $transitionDaysText)
                                .font(.body.monospacedDigit())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }

                        Picker("Target Storage Class", selection: $targetStorageClass) {
                            Text("Infrequent Access").tag("InfrequentAccess")
                        }
                    }
                }

                if let err = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(verbatim: err)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Lifecycle Rule")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveLifecycleRule()
                    }
                    .disabled(ruleId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }

    private func saveLifecycleRule() {
        Task {
            isSaving = true
            errorMessage = nil

            let cleanId = ruleId.trimmingCharacters(in: .whitespacesAndNewlines)
            let conditions = prefix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : R2LifecycleConditions(prefix: prefix.trimmingCharacters(in: .whitespacesAndNewlines))

            let deleteAction = enableExpiration && (Int(expireDaysText) ?? 0) > 0
                ? R2LifecycleDeleteAction(maxAgeSeconds: (Int(expireDaysText) ?? 30) * 86400)
                : nil

            let abortAction = enableAbortMultipart && (Int(abortDaysText) ?? 0) > 0
                ? R2LifecycleDeleteAction(maxAgeSeconds: (Int(abortDaysText) ?? 7) * 86400)
                : nil

            var transitions: [R2LifecycleTransitionAction]?
            if enableStorageTransition && (Int(transitionDaysText) ?? 0) > 0 {
                transitions = [
                    R2LifecycleTransitionAction(
                        condition: R2LifecycleDeleteAction(maxAgeSeconds: (Int(transitionDaysText) ?? 90) * 86400),
                        storageClass: targetStorageClass
                    )
                ]
            }

            let rule = R2LifecycleRule(
                id: cleanId,
                enabled: isEnabled,
                conditions: conditions,
                actions: R2LifecycleActions(
                    delete: deleteAction,
                    abortMultipartUploads: abortAction,
                    storageClassTransitions: transitions
                )
            )

            let success = await viewModel.addLifecycleRule(rule: rule)
            if success {
                ToastManager.shared.showSuccess("Lifecycle Rule Created", icon: "clock.arrow.2.circlepath")
                HapticManager.notification(.success)
                dismiss()
            } else {
                ToastManager.shared.showError("Failed to Save Rule")
                HapticManager.notification(.error)
            }
            isSaving = false
        }
    }
}

// MARK: - AddR2EventNotificationSheetView

struct AddR2EventNotificationSheetView: View {
    @ObservedObject var viewModel: R2BucketSettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var queueIdText = ""
    @State private var enableCreateEvent = true
    @State private var enableDeleteEvent = true
    @State private var prefix = ""
    @State private var suffix = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. orders-queue or queue-uuid", text: $queueIdText)
                        .font(.body.monospaced())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Destination Queue ID")
                } footer: {
                    Text("The Cloudflare Queue that receives notification messages.")
                }

                Section("Event Types") {
                    Toggle("Object Created (object-create)", isOn: $enableCreateEvent)
                    Toggle("Object Deleted (object-delete)", isOn: $enableDeleteEvent)
                }

                Section {
                    TextField("e.g. images/", text: $prefix)
                        .font(.body.monospaced())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Prefix Filter (Optional)")
                }

                Section {
                    TextField("e.g. .jpg or .mp4", text: $suffix)
                        .font(.body.monospaced())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Suffix Filter (Optional)")
                }

                if let err = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(verbatim: err)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Notification")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNotification()
                    }
                    .disabled(queueIdText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (!enableCreateEvent && !enableDeleteEvent) || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }

    private func saveNotification() {
        Task {
            isSaving = true
            errorMessage = nil

            let cleanQueue = queueIdText.trimmingCharacters(in: .whitespacesAndNewlines)
            var actions: [String] = []
            if enableCreateEvent { actions.append("object-create") }
            if enableDeleteEvent { actions.append("object-delete") }

            let cleanPrefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : prefix.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanSuffix = suffix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : suffix.trimmingCharacters(in: .whitespacesAndNewlines)

            let rule = R2EventNotificationRule(
                prefix: cleanPrefix,
                suffix: cleanSuffix,
                actions: actions
            )

            let success = await viewModel.addEventNotification(queueId: cleanQueue, rules: [rule])
            if success {
                ToastManager.shared.showSuccess("Notification Configured", icon: "bell.badge.fill")
                HapticManager.notification(.success)
                dismiss()
            } else {
                ToastManager.shared.showError("Failed to Configure Notification")
                HapticManager.notification(.error)
            }
            isSaving = false
        }
    }
}
