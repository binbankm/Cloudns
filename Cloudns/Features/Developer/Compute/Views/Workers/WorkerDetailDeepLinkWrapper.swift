import SwiftUI

// MARK: - WorkerDetailDeepLinkWrapper

struct WorkerDetailDeepLinkWrapper: View {
    let workerId: String
    let onDismiss: () -> Void
    
    @State private var loadedWorker: WorkerScript?
    @State private var accountId: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if let worker = loadedWorker, !accountId.isEmpty {
                WorkerDetailView(accountId: accountId, worker: worker)
            } else if isLoading {
                WorkerDetailView(accountId: "account-placeholder", worker: WorkerScript(id: workerId.isEmpty ? "worker-service" : workerId))
                    .skeletonLoading(true)
            } else {
                VStack(spacing: CloudnsSpacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(CloudnsColor.brandAccent)
                    CloudnsButton("Close", style: .secondary) {
                        onDismiss()
                    }
                }
                .padding()
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    onDismiss()
                }
            }
        }
        .task {
            await loadWorker()
        }
    }
    
    private func loadWorker() async {
        guard !workerId.isEmpty, workerId != "placeholder-worker", workerId != "placeholder" else {
            onDismiss()
            return
        }
        
        isLoading = true
        
        // 1. Resolve Account ID
        if let accounts = try? await ZoneService.shared.getAccounts(), let firstAcc = accounts.first {
            self.accountId = firstAcc.id
        } else if let zones = try? await ZoneService.shared.getZones().0, let acc = zones.first?.account {
            self.accountId = acc.id
        }
        
        guard !accountId.isEmpty else {
            errorMessage = "No Active Cloudflare Account Found"
            isLoading = false
            return
        }
        
        // 2. Fetch Workers list to match
        if let workers = try? await WorkerService.shared.listWorkers(accountId: accountId),
           let matched = workers.first(where: { $0.id == workerId || $0.id_field == workerId || $0.id_name == workerId }) {
            self.loadedWorker = matched
            self.isLoading = false
        } else {
            // Fallback: Create WorkerScript with ID directly
            self.loadedWorker = WorkerScript(id: workerId)
            self.isLoading = false
        }
    }
}
