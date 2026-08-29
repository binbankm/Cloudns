import Foundation
import SwiftUI

// MARK: - QueuesView

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
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(CFQueue.placeholders) { placeholderQueue in
                        queueRow(placeholderQueue)
                    }
                }
                .redacted(reason: .placeholder)
            } else if !viewModel.filteredQueues.isEmpty {
                Section(header: Text("Message Queues (\(viewModel.queues.count))")) {
                    ForEach(viewModel.filteredQueues) { queue in
                        NavigationLink(destination: QueueDetailView(accountId: accountId, queue: queue, viewModel: viewModel)) {
                            queueRow(queue)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                queueToDelete = queue
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
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
        .scrollDismissesKeyboard(.interactively)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search Queues"
        )
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
        .overlay {
            if viewModel.hasFetchedData {
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
                } else if viewModel.filteredQueues.isEmpty && !viewModel.searchText.isEmpty {
                    HIGContentState(.search(query: viewModel.searchText))
                }
            }
        }
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
                .foregroundStyle(.orange)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(queue.queueName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    if let consumers = queue.consumers {
                        Text("\(consumers.count) consumer\(consumers.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let created = queue.createdOn {
                        Text("• Created \(DateFormatters.formatISO8601ToDisplay(created, style: DateFormatters.dateOnly))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if let producers = queue.producers, !producers.isEmpty {
                HIGBadge(.custom(color: .orange, text: "\(producers.count) producers"), isCompact: true)
            } else {
                HIGBadge(.active, isCompact: true)
            }
        }
        .padding(.vertical, 3)
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
                                HIGFeedback.success()
                                dismiss()
                            } else {
                                HIGFeedback.error()
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
