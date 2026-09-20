import SwiftUI

// MARK: - QueueDetailView

// Apple HIG Compliant Cloudflare Queue Detail & Consumer/Producer Topology

struct QueueDetailView: View {
    let accountId: String
    let initialQueue: CFQueue
    @ObservedObject var viewModel: QueuesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentQueue: CFQueue
    @State private var showingDeleteAlert = false
    @State private var showingPurgeAlert = false
    @State private var showingBindConsumerSheet = false
    @State private var showingEditSettingsSheet = false
    @State private var consumerToDelete: CFQueueConsumer?
    @State private var showingDeleteConsumerConfirm = false

    init(accountId: String, queue: CFQueue, viewModel: QueuesViewModel) {
        self.accountId = accountId
        self.initialQueue = queue
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._currentQueue = State(initialValue: queue)
    }

    var body: some View {
        List {
            overviewSection
            producersSection
            consumersSection
            dangerZoneSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(currentQueue.queueName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditSettingsSheet = true
                    } label: {
                        Label("Queue Settings", systemImage: "slider.horizontal.3")
                    }

                    Button {
                        showingBindConsumerSheet = true
                    } label: {
                        Label("Bind Consumer", systemImage: "arrow.down.left.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingBindConsumerSheet) {
            BindConsumerSheetView(accountId: accountId, queueId: currentQueue.id, viewModel: viewModel) {
                await refreshQueueData()
            }
        }
        .sheet(isPresented: $showingEditSettingsSheet) {
            EditQueueSettingsSheetView(queue: currentQueue, viewModel: viewModel) { updated in
                currentQueue = updated
            }
        }
        .confirmationDialog("Delete Consumer", isPresented: $showingDeleteConsumerConfirm, titleVisibility: .visible) {
            if let c = consumerToDelete {
                let name = c.scriptName ?? c.service ?? String(localized: "Consumer")
                Button("Delete Consumer '\(name)'", role: .destructive) {
                    Task {
                        let success = await viewModel.deleteConsumer(queueId: currentQueue.id, consumerId: c.id)
                        if success {
                            ToastManager.shared.showSuccess("Consumer Unbound", icon: "trash.fill")
                            HapticManager.notification(.success)
                            await refreshQueueData()
                        } else {
                            ToastManager.shared.showError("Failed to Unbind Consumer")
                            HapticManager.notification(.error)
                        }
                        consumerToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                consumerToDelete = nil
            }
        } message: {
            Text("Are you sure you want to unbind this consumer from the queue?")
        }
        .confirmationDialog("Delete Queue", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
            Button("Delete '\(currentQueue.queueName)'", role: .destructive) {
                Task {
                    await viewModel.deleteQueue(queueId: currentQueue.id)
                    ToastManager.shared.showSuccess("Queue Deleted", icon: "trash.fill")
                    HapticManager.notification(.success)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to permanently delete queue '\(currentQueue.queueName)'?")
        }
        .confirmationDialog("Purge Messages", isPresented: $showingPurgeAlert, titleVisibility: .visible) {
            Button("Purge All Messages in '\(currentQueue.queueName)'", role: .destructive) {
                Task {
                    await viewModel.purgeQueue(queueId: currentQueue.id)
                    ToastManager.shared.showSuccess("Queue Purged", icon: "xmark.bin.fill")
                    HapticManager.notification(.success)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to purge all unconsumed messages in '\(currentQueue.queueName)'?")
        }
        .refreshable {
            await refreshQueueData()
        }
        .task {
            await refreshQueueData()
        }
    }

    private func refreshQueueData() async {
        if let refreshed = await viewModel.refreshQueue(queueId: currentQueue.id) {
            currentQueue = refreshed
        }
    }

    private var overviewSection: some View {
        Section {
            LabeledContent("Queue Name", value: currentQueue.queueName)

            if let id = currentQueue.queueId {
                LabeledContent("Queue ID") {
                    Text(id)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                .contextMenu {
                    Button {
                        copyToClipboard(id, toast: "Queue ID Copied")
                    } label: {
                        Label("Copy Queue ID", systemImage: "doc.on.doc")
                    }
                }
            }

            if let delay = currentQueue.settings?.deliveryDelay {
                LabeledContent("Delivery Delay", value: "\(delay)s")
            } else {
                LabeledContent("Delivery Delay", value: "0s")
            }

            if let ret = currentQueue.settings?.messageRetentionPeriod {
                LabeledContent("Retention Period", value: "\(ret / 86400) days (\(ret)s)")
            } else {
                LabeledContent("Retention Period", value: "4 days (345600s)")
            }
        } header: {
            HStack {
                Text("Queue Overview")
                Spacer()
                Button("Edit") {
                    showingEditSettingsSheet = true
                }
                .font(.caption.weight(.semibold))
            }
        }
    }

    @ViewBuilder
    private var producersSection: some View {
        if let producers = currentQueue.producers, !producers.isEmpty {
            Section(header: Text("Producers (\(producers.count))")) {
                ForEach(producers) { p in
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "arrow.up.right", color: .blue)
                        Text(p.script ?? p.service ?? String(localized: "Worker"))
                            .font(.body)
                        Spacer()
                        if let env = p.environment {
                            Text(env)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var consumersSection: some View {
        Section {
            if let consumers = currentQueue.consumers, !consumers.isEmpty {
                ForEach(consumers) { c in
                    consumerRow(c)
                        .contextMenu {
                            Button {
                                if let s = c.scriptName ?? c.service {
                                    copyToClipboard(s, toast: "Consumer Copied")
                                }
                            } label: {
                                Label("Copy Script Name", systemImage: "doc.on.doc")
                            }

                            Divider()

                            Button(role: .destructive) {
                                consumerToDelete = c
                                showingDeleteConsumerConfirm = true
                                HapticManager.impact(.medium)
                            } label: {
                                Label("Unbind Consumer", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                consumerToDelete = c
                                showingDeleteConsumerConfirm = true
                                HapticManager.impact(.medium)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                }
            } else {
                Text("No consumers connected. Bind a Worker script to start processing messages.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } header: {
            HStack {
                let count = currentQueue.consumers?.count ?? 0
                Text("Consumers (\(count))")
                Spacer()
                Button {
                    showingBindConsumerSheet = true
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func consumerRow(_ c: CFQueueConsumer) -> some View {
        HStack(spacing: 12) {
            ListRowIcon(icon: "arrow.down.left", color: .green)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(c.scriptName ?? c.service ?? String(localized: "Worker"))
                        .font(.body.weight(.medium))
                    if let env = c.environment, !env.isEmpty {
                        Text(env)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                            .background(Capsule().fill(Color(.tertiarySystemFill)))
                    }
                }

                HStack(spacing: 8) {
                    if let batch = c.settings?.batchSize {
                        Text("Batch: \(batch)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if let timeout = c.settings?.maxBatchTimeout {
                        Text("Timeout: \(timeout)s")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if let retries = c.settings?.maxRetries {
                        Text("Retries: \(retries)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if let dlq = c.deadLetterQueue, !dlq.isEmpty {
                    HStack(spacing: 4) {
                        Text("DLQ:")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(dlq)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var dangerZoneSection: some View {
        Section(header: Text("Danger Zone")) {
            Button(role: .destructive) {
                showingPurgeAlert = true
                HapticManager.impact(.medium)
            } label: {
                Label("Purge All Messages", systemImage: "xmark.bin")
            }

            Button(role: .destructive) {
                showingDeleteAlert = true
                HapticManager.impact(.medium)
            } label: {
                Label("Delete Queue", systemImage: "trash")
            }
        }
    }
}

// MARK: - BindConsumerSheetView

struct BindConsumerSheetView: View {
    let accountId: String
    let queueId: String
    @ObservedObject var viewModel: QueuesViewModel
    let onDone: () async -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var serviceName = ""
    @State private var environmentName = ""
    @State private var batchSizeText = "10"
    @State private var timeoutText = "5"
    @State private var maxRetriesText = "3"
    @State private var deadLetterQueueName = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Worker Script Name", text: $serviceName)
                        .font(.body.monospaced())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Environment (Optional, e.g. production)", text: $environmentName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Target Worker")
                } footer: {
                    Text("The Worker that will consume messages from this queue via the queue() handler.")
                }

                Section("Consumer Settings") {
                    HStack {
                        Text("Max Batch Size")
                        Spacer()
                        TextField("10", text: $batchSizeText)
                            .font(.body.monospacedDigit())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Max Batch Timeout (Seconds)")
                        Spacer()
                        TextField("5", text: $timeoutText)
                            .font(.body.monospacedDigit())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Max Retries")
                        Spacer()
                        TextField("3", text: $maxRetriesText)
                            .font(.body.monospacedDigit())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                Section {
                    TextField("Queue Name (Optional)", text: $deadLetterQueueName)
                        .font(.body.monospaced())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Dead Letter Queue (DLQ)")
                } footer: {
                    Text("Unprocessed messages exceeding max retries will be delivered to this queue.")
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
            .navigationTitle("Bind Consumer")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bind") {
                        bindConsumerAction()
                    }
                    .disabled(serviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }

    private func bindConsumerAction() {
        Task {
            isSaving = true
            errorMessage = nil

            let cleanService = serviceName.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanEnv = environmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : environmentName.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanDlq = deadLetterQueueName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : deadLetterQueueName.trimmingCharacters(in: .whitespacesAndNewlines)

            let settings = CFQueueConsumerSettings(
                batchSize: Int(batchSizeText) ?? 10,
                maxBatchTimeout: Int(timeoutText) ?? 5,
                maxRetries: Int(maxRetriesText) ?? 3
            )

            let create = CFQueueConsumerCreate(
                service: cleanService,
                environment: cleanEnv,
                deadLetterQueue: cleanDlq,
                type: "worker",
                settings: settings
            )

            let success = await viewModel.bindConsumer(queueId: queueId, consumer: create)
            if success {
                ToastManager.shared.showSuccess("Consumer Bound", icon: "arrow.down.left.circle.fill")
                HapticManager.notification(.success)
                await onDone()
                dismiss()
            } else {
                ToastManager.shared.showError("Failed to Bind Consumer")
                HapticManager.notification(.error)
            }
            isSaving = false
        }
    }
}

// MARK: - EditQueueSettingsSheetView

struct EditQueueSettingsSheetView: View {
    let queue: CFQueue
    @ObservedObject var viewModel: QueuesViewModel
    let onSaved: (CFQueue) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var deliveryDelayText: String
    @State private var retentionDaysText: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(queue: CFQueue, viewModel: QueuesViewModel, onSaved: @escaping (CFQueue) -> Void) {
        self.queue = queue
        self.viewModel = viewModel
        self.onSaved = onSaved
        let delay = queue.settings?.deliveryDelay ?? 0
        let retDays = (queue.settings?.messageRetentionPeriod ?? 345600) / 86400
        _deliveryDelayText = State(initialValue: "\(delay)")
        _retentionDaysText = State(initialValue: "\(retDays)")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Delivery Delay (Seconds)")
                        Spacer()
                        TextField("0", text: $deliveryDelayText)
                            .font(.body.monospacedDigit())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                } header: {
                    Text("Delivery Delay")
                } footer: {
                    Text("The amount of time a message is delayed before being delivered to consumers (0 - 43200 seconds).")
                }

                Section {
                    HStack {
                        Text("Retention Period (Days)")
                        Spacer()
                        TextField("4", text: $retentionDaysText)
                            .font(.body.monospacedDigit())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                } header: {
                    Text("Message Retention")
                } footer: {
                    Text("How long unconsumed messages are kept before being discarded (1 - 14 days).")
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
            .navigationTitle("Queue Settings")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
                    }
                    .disabled(isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }

    private func saveSettings() {
        Task {
            isSaving = true
            errorMessage = nil

            let delay = Int(deliveryDelayText) ?? 0
            let days = Int(retentionDaysText) ?? 4
            let retentionSec = max(86400, min(14 * 86400, days * 86400))

            if let updated = await viewModel.updateQueueSettings(queueId: queue.id, deliveryDelay: delay, messageRetentionPeriod: retentionSec) {
                ToastManager.shared.showSuccess("Settings Saved", icon: "slider.horizontal.3")
                HapticManager.notification(.success)
                onSaved(updated)
                dismiss()
            } else {
                ToastManager.shared.showError("Failed to Save Settings")
                HapticManager.notification(.error)
            }
            isSaving = false
        }
    }
}
