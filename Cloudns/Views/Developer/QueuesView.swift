import Foundation
import SwiftUI
import Combine

@MainActor
final class QueuesViewModel: ObservableObject {
    let accountId: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var queues: [CFQueue] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var hasFetchedData: Bool = false
    @Published var errorMessage: String? = nil
    
    init(accountId: String) {
        self.accountId = accountId
    }
    
    var filteredQueues: [CFQueue] {
        if searchText.isEmpty { return queues }
        return queues.filter { $0.queueName.localizedCaseInsensitiveContains(searchText) }
    }
    
    func fetchQueues() async {
        isLoading = true
        errorMessage = nil
        do {
            self.queues = try await apiClient.listQueues(accountId: accountId)
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
            self.hasFetchedData = true
        }
        isLoading = false
    }
    
    func createQueue(name: String) async -> Bool {
        do {
            _ = try await apiClient.createQueue(accountId: accountId, name: name)
            ToastManager.shared.showSuccess("Queue Created", message: name)
            await fetchQueues()
            return true
        } catch {
            ToastManager.shared.showError("Create Failed", message: error.localizedDescription)
            return false
        }
    }
    
    func deleteQueue(queueId: String) async {
        do {
            try await apiClient.deleteQueue(accountId: accountId, queueId: queueId)
            ToastManager.shared.showSuccess("Queue Deleted", message: "")
            await fetchQueues()
        } catch {
            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
        }
    }
    
    func purgeQueue(queueId: String) async {
        do {
            try await apiClient.purgeQueue(accountId: accountId, queueId: queueId)
            ToastManager.shared.showSuccess("Queue Purged", message: "All messages deleted.")
        } catch {
            ToastManager.shared.showError("Purge Failed", message: error.localizedDescription)
        }
    }
}

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
            if viewModel.isLoading && !viewModel.hasFetchedData {
                Section {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else if let err = viewModel.errorMessage, !viewModel.hasFetchedData {
                Section {
                    EmptyStateView.error(message: LocalizedStringKey(err)) {
                        Task { await viewModel.fetchQueues() }
                    }
                }
                .listRowBackground(Color.clear)
            } else if viewModel.queues.isEmpty {
                Section {
                    EmptyStateView(
                        icon: "tray.2.fill",
                        title: "No Queues",
                        message: "Create a Cloudflare Queue to send and receive messages with guaranteed delivery.",
                        actionTitle: "Create Queue",
                        action: { showingCreateSheet = true }
                    )
                }
                .listRowBackground(Color.clear)
            } else if viewModel.filteredQueues.isEmpty {
                Section {
                    EmptyStateView.search(query: viewModel.searchText) {
                        viewModel.searchText = ""
                    }
                }
                .listRowBackground(Color.clear)
            } else {
                Section(header: Text("Message Queues (\(viewModel.queues.count))")) {
                    ForEach(viewModel.filteredQueues) { queue in
                        NavigationLink(destination: QueueDetailView(accountId: accountId, queue: queue, viewModel: viewModel)) {
                            HStack(spacing: 12) {
                                Image(systemName: "tray.2.fill")
                                    .foregroundStyle(.pink)
                                    .font(.title3)
                                    .frame(width: 32, height: 32)
                                    .background(Color.pink.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
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
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                queueToDelete = queue
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
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
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateQueueSheet(viewModel: viewModel)
        }
        .alert("Delete Queue", isPresented: $showingDeleteAlert, presenting: queueToDelete) { q in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteQueue(queueId: q.id) }
            }
        } message: { q in
            Text("Are you sure you want to permanently delete '\(q.queueName)'? Producers and consumers will fail to deliver.")
        }
        .alert("Purge All Messages", isPresented: $showingPurgeAlert, presenting: queueToPurge) { q in
            Button("Cancel", role: .cancel) {}
            Button("Purge Everything", role: .destructive) {
                Task { await viewModel.purgeQueue(queueId: q.id) }
            }
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
        .toastContainer()
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
                    Task { await viewModel.purgeQueue(queueId: queue.id) }
                } label: {
                    Label("Purge All Messages", systemImage: "xmark.bin")
                }
                
                Button(role: .destructive) {
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
