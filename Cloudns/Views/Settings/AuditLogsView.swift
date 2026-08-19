import SwiftUI

struct AuditLogsView: View {
    let accountId: String
    @StateObject private var viewModel: AuditLogsViewModel
    @State private var selectedLog: AuditLog?
    @AppStorage(AppStorageKey.appLanguage) private var appLanguage = "system"
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: AuditLogsViewModel(accountId: accountId))
    }
    
    var body: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(AuditLog.placeholders) { placeholderLog in
                        AuditLogRowView(log: placeholderLog)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
            } else if !viewModel.filteredLogs.isEmpty {
                Section {
                    ForEach(viewModel.filteredLogs) { log in
                        Button {
                            selectedLog = log
                            HapticManager.impact(.light)
                        } label: {
                            AuditLogRowView(log: log)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("Audit Logs")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search actions, domains, or users")
        .id(appLanguage)
        .refreshable {
            await viewModel.fetchLogs()
        }
        .sheet(item: $selectedLog) { log in
            NavigationStack {
                AuditLogDetailSheetView(log: log)
            }
        }
        .overlay {
            if viewModel.hasFetchedData {
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
