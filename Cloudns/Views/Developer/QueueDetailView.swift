import SwiftUI

// MARK: - QueueDetailView

struct QueueDetailView: View {
    let accountId: String
    let queue: CFQueue
    @ObservedObject var viewModel: QueuesViewModel
    
    var body: some View {
        List {
            Section(header: Text("Queue Overview")) {
                LabeledContent("Queue Name", value: queue.queueName)
                
                if let id = queue.queueId {
                    LabeledContent("Queue ID") {
                        Text(id)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let delay = queue.settings?.deliveryDelay {
                    LabeledContent("Delivery Delay", value: "\(delay)s")
                }
                
                if let ret = queue.settings?.messageRetentionPeriod {
                    LabeledContent("Retention Period", value: "\(ret / 86400) days (\(ret)s)")
                }
            }
            
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
            
            if let consumers = queue.consumers, !consumers.isEmpty {
                Section(header: Text("Consumers (\(consumers.count))")) {
                    ForEach(consumers) { c in
                        VStack(alignment: .leading, spacing: 4) {
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
            
            Section(header: Text("Danger Zone")) {
                Button(role: .destructive) {
                    HapticManager.impact(.medium)
                    Task { await viewModel.purgeQueue(queueId: queue.id) }
                } label: {
                    Label("Purge All Messages", systemImage: "xmark.bin")
                }
                
                Button(role: .destructive) {
                    HapticManager.impact(.medium)
                    Task { await viewModel.deleteQueue(queueId: queue.id) }
                } label: {
                    Label("Delete Queue", systemImage: "trash")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(queue.queueName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
