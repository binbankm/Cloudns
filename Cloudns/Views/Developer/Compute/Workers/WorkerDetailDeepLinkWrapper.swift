import SwiftUI

// MARK: - WorkerDetailDeepLinkWrapper

// Apple HIG Compliant Deep Link & Spotlight Resolver for Cloudflare Workers

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
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading Worker…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                NativeErrorStateView(errorMessage: errorMessage ?? String(localized: "Unable to load worker")) {
                    Task { await loadWorker() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    onDismiss()
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.accentColor)
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
            accountId = firstAcc.id
        } else if let zones = try? await ZoneService.shared.getZones().0, let acc = zones.first?.account {
            accountId = acc.id
        }

        guard !accountId.isEmpty else {
            errorMessage = "No Active Cloudflare Account Found"
            isLoading = false
            return
        }

        // 2. Fetch Workers list to match
        if let workers = try? await WorkerService.shared.listWorkers(accountId: accountId),
           let matched = workers.first(where: { $0.id == workerId || $0.id_field == workerId || $0.id_name == workerId }) {
            loadedWorker = matched
            isLoading = false
        } else {
            // Fallback: Create WorkerScript with ID directly
            loadedWorker = WorkerScript(id: workerId)
            isLoading = false
        }
    }
}
