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
                    .higTouchTarget(44)
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateQueueSheetView(viewModel: viewModel)
                    .higToast()
            }
            .confirmationDialog("Delete Queue", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: queueToDelete) { q in
                Button("Delete '\(q.queueName)'", role: .destructive) {
                    Task {
                        await viewModel.deleteQueue(queueId: q.id)
                        ToastManager.shared.showSuccess("Queue Deleted", icon: "trash.fill")
                        HIGFeedback.success()
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
                        HIGFeedback.success()
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
                                UIPasteboard.general.string = queue.queueName
                                ToastManager.shared.showCopied("Queue Name Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy Queue Name", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                UIPasteboard.general.string = queue.id
                                ToastManager.shared.showCopied("Queue ID Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy Queue ID", systemImage: "link")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                queueToPurge = queue
                                showingPurgeAlert = true
                                HIGFeedback.impact(.medium)
                            } label: {
                                Label("Purge Messages", systemImage: "xmark.bin")
                            }
                            
                            Button(role: .destructive) {
                                queueToDelete = queue
                                showingDeleteAlert = true
                                HIGFeedback.impact(.medium)
                            } label: {
                                Label("Delete Queue", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                queueToDelete = queue
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(HIGColors.error)
                            
                            Button {
                                HIGFeedback.impact(.light)
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
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Message Queues…"))
            } else if viewModel.hasFetchedData {
                if let err = viewModel.errorMessage, viewModel.queues.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(err),
                            retryAction: { Task { await viewModel.fetchQueues() } }
                        )
                    )
                } else if viewModel.queues.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Queues Configured",
                            systemImage: "tray.2.fill",
                            description: "Cloudflare Queues provides reliable point-to-point asynchronous messaging between Workers.",
                            actionTitle: "Create Queue",
                            action: { showingCreateSheet = true }
                        )
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func queueRow(_ queue: CFQueue) -> some View {
        HStack(spacing: HIGTokens.Spacing.md) {
            ListRowIcon(icon: "tray.2.fill", color: .indigo)
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text(queue.queueName)
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                HStack(spacing: HIGTokens.Spacing.sm) {
                    if let consumers = queue.consumers {
                        Text("\(consumers.count) Consumers")
                            .font(HIGTypography.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let created = queue.createdOn, let date = DateFormatters.parseISO8601(created) {
                        Text("• Created \(date.displayFormatted(date: .abbreviated, time: .omitted))")
                            .font(HIGTypography.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if let producers = queue.producers, !producers.isEmpty {
                HIGBadge(.custom(color: .orange, text: String(localized: "\(producers.count) producers")), isCompact: true)
            } else {
                HIGBadge(.active, isCompact: true)
            }
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
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
                        .font(HIGTypography.body.monospaced())
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Queue")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .higTouchTarget(44)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            let success = await viewModel.createQueue(name: queueName.trimmingCharacters(in: .whitespaces))
                            if success {
                                ToastManager.shared.showSuccess("Queue Created", icon: "tray.2.fill")
                                HIGFeedback.success()
                                dismiss()
                            } else {
                                ToastManager.shared.showError("Failed to Create Queue")
                                HIGFeedback.error()
                            }
                            isCreating = false
                        }
                    }
                    .disabled(queueName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                    .higTouchTarget(44)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }
}
