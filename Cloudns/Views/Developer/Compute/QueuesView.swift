import Foundation
import SwiftUI

// MARK: - QueuesView
// Apple HIG Compliant Cloudflare Queues Message Hub

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
    
    var body: some View {
        queueListContent
            .navigationTitle("Queues")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create Queue")
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateQueueSheetView(viewModel: viewModel)
            }
            .confirmationDialog("Delete Queue", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: queueToDelete) { q in
                Button("Delete '\(q.queueName)'", role: .destructive) {
                    Task {
                        await viewModel.deleteQueue(queueId: q.id)
                        ToastManager.shared.showSuccess("Queue Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { q in
                Text("Are you sure you want to permanently delete '\(q.queueName)'? Producers and consumers will fail to deliver.")
            }
            .confirmationDialog("Purge All Messages", isPresented: $showingPurgeAlert, titleVisibility: .visible, presenting: queueToPurge) { q in
                Button("Purge All Messages in '\(q.queueName)'", role: .destructive) {
                    Task {
                        await viewModel.purgeQueue(queueId: q.id)
                        ToastManager.shared.showSuccess("Queue Purged", icon: "xmark.bin.fill")
                        HapticManager.notification(.success)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { q in
                Text("Are you sure you want to purge all unconsumed messages in '\(q.queueName)'? This action cannot be undone.")
            }
            .refreshable {
                await viewModel.fetchQueues()
            }
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchQueues()
                }
            }
    }
    
    @ViewBuilder
    private var queueListContent: some View {
        List {
            if !viewModel.queues.isEmpty {
                Section(header: Text("Message Queues (\(viewModel.queues.count))")) {
                    ForEach(viewModel.queues) { queue in
                        NavigationLink(destination: QueueDetailView(accountId: accountId, queue: queue, viewModel: viewModel)) {
                            queueRow(queue)
                        }
                        .contextMenu {
                            Button {
                                copyToClipboard(queue.queueName, toast: "Queue Name Copied")
                            } label: {
                                Label("Copy Queue Name", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                copyToClipboard(queue.id, toast: "Queue ID Copied")
                            } label: {
                                Label("Copy Queue ID", systemImage: "link")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                queueToPurge = queue
                                showingPurgeAlert = true
                                HapticManager.impact(.medium)
                            } label: {
                                Label("Purge Messages", systemImage: "xmark.bin")
                            }
                            
                            Button(role: .destructive) {
                                queueToDelete = queue
                                showingDeleteAlert = true
                                HapticManager.impact(.medium)
                            } label: {
                                Label("Delete Queue", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                queueToDelete = queue
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                            
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
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Message Queues…",
            isEmpty: viewModel.hasFetchedData && viewModel.queues.isEmpty,
            emptyTitle: "No Queues Configured",
            emptySystemImage: "tray.2.fill",
            emptyDescription: "Cloudflare Queues provides reliable point-to-point asynchronous messaging between Workers.",
            emptyActionTitle: "Create Queue",
            emptyAction: { showingCreateSheet = true },
            errorMessage: (viewModel.hasFetchedData && viewModel.queues.isEmpty) ? viewModel.errorMessage.map { LocalizedStringKey($0) } : nil,
            retryAction: { Task { await viewModel.fetchQueues() } }
        )
    }
    
    @ViewBuilder
    private func queueRow(_ queue: CFQueue) -> some View {
        HStack(spacing: 12) {
            ListRowIcon(icon: "tray.2.fill", color: .indigo)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(queue.queueName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    if let consumers = queue.consumers {
                        Text("\(consumers.count) Consumers")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let created = queue.createdOn, let date = DateFormatters.parseISO8601(created) {
                        Text("• Created \(date.displayFormatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if let producers = queue.producers, !producers.isEmpty {
                Text("\(producers.count) producers")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.orange.opacity(0.12)))
            } else {
                Text("Active")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.green.opacity(0.12)))
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - CreateQueueSheetView (Inlined & Cohesive)

struct CreateQueueSheetView: View {
    @ObservedObject var viewModel: QueuesViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var queueName = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Queue Name"), footer: Text("Name your queue using alphanumeric characters and dashes (e.g. auth-events-queue).")) {
                    TextField("my-queue", text: $queueName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.body.monospaced())
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Queue")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            let success = await viewModel.createQueue(name: queueName.trimmingCharacters(in: .whitespaces))
                            if success {
                                ToastManager.shared.showSuccess("Queue Created", icon: "tray.2.fill")
                                HapticManager.notification(.success)
                                dismiss()
                            } else {
                                ToastManager.shared.showError("Failed to Create Queue")
                                HapticManager.notification(.error)
                            }
                            isCreating = false
                        }
                    }
                    .disabled(queueName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }
}
