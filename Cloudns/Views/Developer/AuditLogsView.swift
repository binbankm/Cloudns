import SwiftUI

struct AuditLogsView: View {
    let accountId: String
    @StateObject private var viewModel: AuditLogsViewModel
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: AuditLogsViewModel(accountId: accountId))
    }
    
    var body: some View {
        List {
            if !viewModel.filteredLogs.isEmpty {
                Section {
                    ForEach(viewModel.filteredLogs) { log in
                        AuditLogRowView(log: log)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("Audit Logs")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Actions or Users")
        .refreshable {
            await viewModel.fetchLogs()
        }
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.logs.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchLogs() } }
                        )
                    )
                } else if viewModel.logs.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "list.clipboard.fill",
                            title: "No Audit Logs",
                            message: "No recent account audit logs or modification records found."
                        )
                    )
                } else if viewModel.filteredLogs.isEmpty && !viewModel.searchText.isEmpty {
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
                await viewModel.fetchLogs()
            }
        }
    }
}

struct AuditLogRowView: View {
    let log: AuditLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(log.action?.type ?? "action")
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if let res = log.action?.result {
                    CloudnsBadge(res ? .active("Success") : .error("Failed"), isCompact: true)
                }
            }
            
            HStack(spacing: 10) {
                if let email = log.actor?.email {
                    Label(email, systemImage: "person.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let ip = log.actor?.ip {
                    Text(ip)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            
            if let when = log.when {
                Text(String(when.prefix(19)).replacingOccurrences(of: "T", with: " "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}
