import SwiftUI

struct TurnstileWidgetsView: View {
    let accountId: String
    @StateObject private var viewModel: TurnstileViewModel
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: TurnstileViewModel(accountId: accountId))
    }
    
    var body: some View {
        contentView
            .navigationTitle("Turnstile Widgets")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Widgets")
            .refreshable {
                await viewModel.fetchWidgets()
            }
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchWidgets()
                }
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)

            if viewModel.isLoading && !viewModel.hasFetchedData {
                List {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
                .listStyle(.insetGrouped)
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                EmptyStateView.error(
                    message: LocalizedStringKey(errorMessage),
                    retryAction: {
                        Task { await viewModel.fetchWidgets() }
                    }
                )
            } else if viewModel.widgets.isEmpty {
                EmptyStateView(
                    icon: "checkmark.shield.fill",
                    title: "No Turnstile Widgets",
                    message: "You haven't created any Turnstile captcha widgets in this account yet.",
                    actionTitle: nil,
                    action: nil
                )
            } else if viewModel.filteredWidgets.isEmpty {
                EmptyStateView.search(query: viewModel.searchText) {
                    viewModel.searchText = ""
                }
            } else {
                List {
                    ForEach(viewModel.filteredWidgets) { widget in
                        TurnstileWidgetRowView(widget: widget)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

struct TurnstileWidgetRowView: View {
    let widget: TurnstileWidget
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "checkmark.shield.fill")
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(widget.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    if let mode = widget.mode {
                        Text(mode.capitalized)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12))
                            .cornerRadius(4)
                    }
                }
                
                Text(widget.sitekey)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 3)
        .contextMenu {
            Button {
                UIPasteboard.general.string = widget.sitekey
                ToastManager.shared.showCopied("Sitekey copied")
            } label: {
                Label("Copy Sitekey", systemImage: "doc.on.doc")
            }
        }
    }
}
