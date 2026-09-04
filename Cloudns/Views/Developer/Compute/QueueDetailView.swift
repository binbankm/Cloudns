import SwiftUI

// MARK: - QueueDetailView
// Apple HIG Compliant Cloudflare Queue Detail & Consumer/Producer Topology

struct QueueDetailView: View {
    let accountId: String
    let queue: CFQueue
    @ObservedObject var viewModel: QueuesViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDeleteAlert = false
    @State private var showingPurgeAlert = false
    
    var body: some View {
        List {
            overviewSection
            producersSection
            consumersSection
            dangerZoneSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(queue.queueName)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete Queue", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
            Button("Delete '\(queue.queueName)'", role: .destructive) {
                Task {
                    await viewModel.deleteQueue(queueId: queue.id)
                    ToastManager.shared.showSuccess("Queue Deleted", icon: "trash.fill")
                    HapticManager.notification(.success)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to permanently delete queue '\(queue.queueName)'?")
        }
        .confirmationDialog("Purge Messages", isPresented: $showingPurgeAlert, titleVisibility: .visible) {
            Button("Purge All Messages in '\(queue.queueName)'", role: .destructive) {
                Task {
                    await viewModel.purgeQueue(queueId: queue.id)
                    ToastManager.shared.showSuccess("Queue Purged", icon: "xmark.bin.fill")
                    HapticManager.notification(.success)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to purge all unconsumed messages in '\(queue.queueName)'?")
        }
    }
    
    @ViewBuilder
    private var overviewSection: some View {
        Section(header: Text("Queue Overview")) {
            LabeledContent("Queue Name", value: queue.queueName)
            
            if let id = queue.queueId {
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
            
            if let delay = queue.settings?.deliveryDelay {
                LabeledContent("Delivery Delay", value: "\(delay)s")
            }
            
            if let ret = queue.settings?.messageRetentionPeriod {
                LabeledContent("Retention Period", value: "\(ret / 86400) days (\(ret)s)")
            }
        }
    }
    
    @ViewBuilder
    private var producersSection: some View {
        if let producers = queue.producers, !producers.isEmpty {
            Section(header: Text("Producers (\(producers.count))")) {
                ForEach(producers) { p in
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "arrow.up.right", color: .blue)
                        Text(p.script ?? p.service ?? "Worker")
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
        if let consumers = queue.consumers, !consumers.isEmpty {
            Section(header: Text("Consumers (\(consumers.count))")) {
                ForEach(consumers) { c in
                    HStack(spacing: 12) {
                        ListRowIcon(icon: "arrow.down.left", color: .green)
                        Text(c.scriptName ?? c.service ?? "Worker")
                            .font(.body.weight(.medium))
                        Spacer()
                        if let batch = c.settings?.batchSize {
                            Text("Batch: \(batch)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
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
