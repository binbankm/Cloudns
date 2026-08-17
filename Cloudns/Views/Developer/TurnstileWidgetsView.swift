import SwiftUI

struct TurnstileWidgetsView: View {
    let accountId: String
    @StateObject private var viewModel: TurnstileViewModel
    @State private var showingCreateSheet = false
    @State private var widgetToDelete: TurnstileWidget? = nil
    @State private var showingDeleteAlert = false
    
    init(accountId: String) {
        self.accountId = accountId
        _viewModel = StateObject(wrappedValue: TurnstileViewModel(accountId: accountId))
    }
    
    var body: some View {
        List {
            if !viewModel.filteredWidgets.isEmpty {
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
            if !viewModel.hasFetchedData && viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.hasFetchedData {
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
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(widget.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    if let mode = widget.mode {
                        CloudnsBadge(.custom(color: .blue, text: mode.capitalized), isCompact: true)
                    }
                }
                
                Text(widget.sitekey)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                UIPasteboard.general.string = widget.sitekey
                HapticManager.impact(.light)
                ToastManager.shared.showCopied("Sitekey copied")
            } label: {
                Label("Copy Sitekey", systemImage: "doc.on.doc")
            }
        }
    }
}

struct CreateTurnstileWidgetSheetView: View {
    @ObservedObject var viewModel: TurnstileViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var widgetName = ""
    @State private var domainsText = "example.com"
    @State private var selectedMode = "managed"
    @State private var isSubmitting = false
    
    private let modes = [
        ("managed", "Managed", "Cloudflare decides when to challenge users with an interactive checkbox."),
        ("non-interactive", "Non-Interactive", "Users see a loading spinner while verification is run silently."),
        ("invisible", "Invisible", "Verification is completely hidden in the background without UI elements.")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("General Information")) {
                    TextField("Widget Name (e.g. My Website Login)", text: $widgetName)
                }
                
                Section(header: Text("Widget Mode"), footer: Text(modes.first(where: { $0.0 == selectedMode })?.2 ?? "")) {
                    Picker("Challenge Mode", selection: $selectedMode) {
                        ForEach(modes, id: \.0) { mode in
                            Text(mode.1).tag(mode.0)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Allowed Domains"), footer: Text("Enter hostnames allowed to display this Turnstile widget, separated by comma or newlines.")) {
                    TextField("Domains (e.g. example.com, app.example.com)", text: $domainsText, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Turnstile Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        submit()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Create")
                        }
                    }
                    .disabled(widgetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
        }
    }
    
    private func submit() {
        let name = widgetName.trimmingCharacters(in: .whitespacesAndNewlines)
        let domains = domainsText
            .split(separator: ",")
            .flatMap { $0.split(separator: "\n") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        isSubmitting = true
        Task {
            do {
                _ = try await viewModel.createWidget(name: name, domains: domains.isEmpty ? ["*"] : domains, mode: selectedMode)
                HapticManager.impact(.medium)
                ToastManager.shared.showSuccess("Widget Created", message: name)
                dismiss()
            } catch {
                ToastManager.shared.showError("Creation Failed", message: error.localizedDescription)
            }
            isSubmitting = false
        }
    }
}
