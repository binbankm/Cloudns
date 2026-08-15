import SwiftUI

struct AuditLogsView: View {
    let accountId: String
    @StateObject private var viewModel: AuditLogsViewModel
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: AuditLogsViewModel(accountId: accountId))
    }
    
    var body: some View {
        contentView
            .navigationTitle("Audit Logs")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Actions or Users")
            .refreshable {
                await viewModel.fetchLogs()
            }
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchLogs()
                }
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if viewModel.isLoading && !viewModel.hasFetchedData {
                Section {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                EmptyStateView.error(
                    message: LocalizedStringKey(errorMessage),
                    retryAction: {
                        Task { await viewModel.fetchLogs() }
                    }
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else if viewModel.logs.isEmpty {
                EmptyStateView(
                    icon: "list.clipboard.fill",
                    title: "No Audit Logs",
                    message: "No recent account audit logs or modification records found.",
                    actionTitle: nil,
                    action: nil
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else if viewModel.filteredLogs.isEmpty {
                EmptyStateView.search(query: viewModel.searchText) {
                    viewModel.searchText = ""
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } else {
                ForEach(viewModel.filteredLogs) { log in
                    AuditLogRowView(log: log)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct AuditLogRowView: View {
    let log: AuditLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(log.action?.type ?? "action")
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let res = log.action?.result {
                    Text(res ? "Success" : "Failed")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(res ? .green : .red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((res ? Color.green : Color.red).opacity(0.12))
                        .cornerRadius(4)
                }
            }
            
            HStack(spacing: 10) {
                if let email = log.actor?.email {
                    Label(email, systemImage: "person.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let ip = log.actor?.ip {
                    Text(ip)
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }
            
            if let when = log.when {
                Text(String(when.prefix(19)).replacingOccurrences(of: "T", with: " "))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}
