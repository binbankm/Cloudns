import Foundation
import SwiftUI

struct QueuesView: View {
    let accountId: String
    @StateObject private var viewModel: QueuesViewModel
    @State private var showingCreateSheet = false
    @State private var queueToDelete: CFQueue?
    @State private var queueToPurge: CFQueue?
    @State private var showingDeleteAlert = false
    @State private var showingPurgeAlert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: QueuesViewModel(accountId: accountId))
    }
    
    // Skeleton-only list — no .searchable, prevents overlap
    @ViewBuilder
    private var skeletonContent: some View {
        List {
            Section(header: Text("Message Queues")) {
                ForEach(CFQueue.placeholders) { queue in
                    queueRow(queue)
                        .skeletonLoading(true)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Queues")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { } label: { Image(systemName: "plus") }
                    .disabled(true)
                    .accessibilityLabel("Create Queue")
            }
        }
    }

    // Data-ready list — gets .searchable safely
    @ViewBuilder
    private var dataContent: some View {
        List {
            if !viewModel.filteredQueues.isEmpty {
                Section(header: Text("Message Queues (\(viewModel.queues.count))")) {
                    ForEach(viewModel.filteredQueues) { queue in
                        NavigationLink(destination: QueueDetailView(accountId: accountId, queue: queue, viewModel: viewModel)) {
                            queueRow(queue)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                queueToDelete = queue
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                HapticManager.impact(.light)
                                queueToPurge = queue
                                showingPurgeAlert = true
                            } label: {
                                Label("Purge", systemImage: "xmark.bin")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if let err = viewModel.errorMessage, viewModel.queues.isEmpty {
                StateOverlayView(
                    state: .error(
                        message: LocalizedStringKey(err),
                        retryAction: { Task { await viewModel.fetchQueues() } }
                    )
                )
            } else if viewModel.queues.isEmpty {
                StateOverlayView(
                    state: .empty(
                        icon: "tray.2.fill",
                        title: "No Queues",
                        message: "Create a Cloudflare Queue to send and receive messages with guaranteed delivery.",
                        actionTitle: "Create Queue",
                        action: { showingCreateSheet = true }
                    )
                )
            } else if viewModel.filteredQueues.isEmpty && !viewModel.searchText.isEmpty {
                StateOverlayView(
                    state: .search(
                        query: viewModel.searchText,
                        clearAction: { viewModel.searchText = "" }
                    )
                )
            }
        }
        .navigationTitle("Queues")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "Search Queues")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create Queue")
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateQueueSheet(viewModel: viewModel)
        }
        .confirmationDialog("Delete Queue", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: queueToDelete) { q in
            Button("Delete '\(q.queueName)'", role: .destructive) {
                Task { await viewModel.deleteQueue(queueId: q.id) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { q in
            Text("Are you sure you want to permanently delete '\(q.queueName)'? Producers and consumers will fail to deliver.")
        }
        .confirmationDialog("Purge All Messages", isPresented: $showingPurgeAlert, titleVisibility: .visible, presenting: queueToPurge) { q in
            Button("Purge All Messages in '\(q.queueName)'", role: .destructive) {
                Task { await viewModel.purgeQueue(queueId: q.id) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { q in
            Text("Are you sure you want to purge all unconsumed messages in '\(q.queueName)'? This action cannot be undone.")
        }
        .refreshable {
            await viewModel.fetchQueues()
        }
        .toastContainer()
    }

    var body: some View {
        Group {
            if !viewModel.hasFetchedData {
                skeletonContent
            } else {
                dataContent
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.hasFetchedData)
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchQueues()
            }
        }
    }
    
    @ViewBuilder
    private func queueRow(_ queue: CFQueue) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "tray.2.fill")
                .foregroundStyle(.pink)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(Color.pink.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(queue.queueName)
                    .font(.body.weight(.medium))
                
                if let created = queue.createdOn {
                    Text("Created: \(String(created.prefix(10)))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if queue.settings?.deliveryPaused == true {
                Text("Paused")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.vertical, 2)
    }
}

struct QueueDetailView: View {
    let accountId: String
    let queue: CFQueue
    @ObservedObject var viewModel: QueuesViewModel
    
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

struct CreateQueueSheet: View {
    @ObservedObject var viewModel: QueuesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var queueName = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Queue Name"), footer: Text("Queue names must contain only lowercase alphanumeric characters and hyphens.")) {
                    TextField("my-queue", text: $queueName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("New Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            isSubmitting = true
                            let clean = queueName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                            let success = await viewModel.createQueue(name: clean)
                            if success { dismiss() }
                            isSubmitting = false
                        }
                    }
                    .disabled(queueName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
        }
    }
}
