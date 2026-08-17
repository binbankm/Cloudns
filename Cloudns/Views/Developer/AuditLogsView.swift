import SwiftUI

struct AuditLogsView: View {
    let accountId: String
    @StateObject private var viewModel: AuditLogsViewModel
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: AuditLogsViewModel(accountId: accountId))
    }
    
    var body: some View {
        Group {
            if !viewModel.hasFetchedData {
                List {
                    Section {
                        ForEach(AuditLog.placeholders) { log in
                            AuditLogRowView(log: log)
                                .skeletonLoading(true)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Audit Logs")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                contentView
                    .navigationTitle("Audit Logs")
                    .navigationBarTitleDisplayMode(.inline)
                    .searchable(text: $viewModel.searchText, prompt: "Search Actions or Users")
                    .refreshable {
                        await viewModel.fetchLogs()
                    }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.hasFetchedData)
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchLogs()
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
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
        .overlay {
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
                    Text(res ? "Success" : "Failed")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(res ? .green : .red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((res ? Color.green : Color.red).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
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
