import SwiftUI

struct AuditLogsView: View {
    // MARK: - Properties
    let accountId: String
    @StateObject private var viewModel: AuditLogsViewModel
    @State private var selectedLog: AuditLog?
    @AppStorage(AppStorageKey.appLanguage) private var appLanguage = "system"
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: AuditLogsViewModel(accountId: accountId))
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            CloudnsSearchBar(
                text: $viewModel.searchText,
                prompt: "Search Logs"
            )
            .padding(.horizontal, CloudnsSpacing.md)
            .padding(.top, CloudnsSpacing.sm)
            .padding(.bottom, CloudnsSpacing.xs)
            .background(CloudnsColor.groupedBackground)
            
            List {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Section {
                        ForEach(AuditLog.placeholders) { placeholderLog in
                            AuditLogRowView(log: placeholderLog)
                        }
                    }
                    .skeletonLoading(true)
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
            .scrollDismissesKeyboard(.interactively)
            .centerConstrainedWidth(maxWidth: 840)
        }
        .background(CloudnsColor.groupedBackground)
        .navigationTitle("Audit Logs")
        .navigationBarTitleDisplayMode(.inline)
        .id(appLanguage)
        .refreshable {
            await viewModel.fetchLogs()
        }
        .sheet(item: $selectedLog) { log in
            NavigationStack {
                AuditLogDetailSheetView(log: log)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.logs.isEmpty {
                    CloudnsStateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchLogs() } }
                        )
                    )
                } else if viewModel.logs.isEmpty {
                    CloudnsStateOverlayView(
                        state: .empty(
                            icon: "list.clipboard.fill",
                            title: "No Audit Logs",
                            message: "No recent account audit logs or modification records found."
                        )
                    )
                } else if viewModel.filteredLogs.isEmpty && !viewModel.searchText.isEmpty {
                    CloudnsStateOverlayView(
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
