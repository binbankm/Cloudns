import SwiftUI

struct TurnstileWidgetsView: View {
    let accountId: String
    @StateObject private var viewModel: TurnstileViewModel
    @State private var showingCreateSheet = false
    @State private var widgetToDelete: TurnstileWidget?
    @State private var showingDeleteAlert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: TurnstileViewModel(accountId: accountId))
    }
    
    var body: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(TurnstileWidget.placeholders) { placeholder in
                        TurnstileWidgetRowView(widget: placeholder)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
            } else if !viewModel.filteredWidgets.isEmpty {
                Section {
                    ForEach(viewModel.filteredWidgets) { widget in
                        NavigationLink(destination: TurnstileDetailView(widget: widget, viewModel: viewModel)) {
                            TurnstileWidgetRowView(widget: widget)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                widgetToDelete = widget
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("Turnstile Widgets")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Widgets")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create Turnstile Widget")
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateTurnstileWidgetSheetView(viewModel: viewModel)
        }
        .confirmationDialog("Delete Turnstile Widget", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: widgetToDelete) { widget in
            Button("Delete '\(widget.name)'", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteWidget(sitekey: widget.sitekey)
                        ToastManager.shared.showSuccess("Widget Deleted", message: widget.name)
                    } catch {
                        ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { widget in
            Text("Are you sure you want to delete widget '\(widget.name)' (\(widget.sitekey))? Any websites using this sitekey will fail human verification.")
        }
        .refreshable {
            await viewModel.fetchWidgets()
        }
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.widgets.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchWidgets() }
                            }
                        )
                    )
                } else if viewModel.widgets.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "checkmark.shield.fill",
                            title: "No Turnstile Widgets",
                            message: "You haven't created any Turnstile captcha widgets in this account yet.",
                            actionTitle: "Add Widget",
                            action: { showingCreateSheet = true }
                        )
                    )
                } else if viewModel.filteredWidgets.isEmpty && !viewModel.searchText.isEmpty {
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
                await viewModel.fetchWidgets()
            }
        }
    }
}
