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
    
    var body: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section(header: Text("Message Queues")) {
                    ForEach(CFQueue.placeholders) { placeholderQueue in
                        queueRow(placeholderQueue)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
            } else if !viewModel.filteredQueues.isEmpty {
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
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("Queues")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Queues")
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
                .foregroundStyle(.pink)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(Color.pink.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(queue.queueName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                if let created = queue.createdOn {
                    Text("Created: \(DateFormatters.formatISO8601ToDisplay(created, style: DateFormatters.dateOnly))")
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
