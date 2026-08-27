import SwiftUI

// MARK: - QueueDetailView

struct QueueDetailView: View {
    // MARK: - Properties
    let accountId: String
    let queue: CFQueue
    @ObservedObject var viewModel: QueuesViewModel
    
    // MARK: - Body
    var body: some View {
        List {
            Section(header: Text("Queue Overview")) {
                HStack {
                    Text("Queue Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(queue.queueName)
                        .font(.body.weight(.medium))
                }
                
                if let id = queue.queueId {
                    HStack {
                        Text("Queue ID")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(id)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let delay = queue.settings?.deliveryDelay {
                    HStack {
                        Text("Delivery Delay")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(delay)s")
                            .font(.subheadline)
                    }
                }
                
                if let ret = queue.settings?.messageRetentionPeriod {
                    HStack {
                        Text("Retention Period")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(ret / 86400) days (\(ret)s)")
                            .font(.subheadline)
                    }
                }
            }
            
            if let producers = queue.producers, !producers.isEmpty {
                Section(header: Text("Producers (\(producers.count))")) {
                    ForEach(producers) { p in
                        HStack {
                            Image(systemName: "arrow.up.right.circle.fill")
                                .foregroundStyle(.blue)
                                .accessibilityHidden(true)
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
                            HStack {
                                Image(systemName: "arrow.down.left.circle.fill")
                                    .foregroundStyle(.green)
                                    .accessibilityHidden(true)
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
