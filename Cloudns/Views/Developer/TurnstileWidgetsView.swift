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
        contentView
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
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateTurnstileWidgetSheetView(viewModel: viewModel)
            }
            .alert("Delete Turnstile Widget", isPresented: $showingDeleteAlert, presenting: widgetToDelete) { widget in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteWidget(sitekey: widget.sitekey)
                            ToastManager.shared.showSuccess("Widget Deleted", message: widget.name)
                        } catch {
                            ToastManager.shared.showError("Delete Failed", message: error.localizedDescription)
                        }
                    }
                }
            } message: { widget in
                Text("Are you sure you want to delete widget '\(widget.name)' (\(widget.sitekey))? Any websites using this sitekey will fail human verification.")
            }
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
        List {
            if viewModel.isLoading && !viewModel.hasFetchedData {
                Section {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                Section {
                    EmptyStateView.error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task { await viewModel.fetchWidgets() }
                        }
                    )
                }
                .listRowBackground(Color.clear)
            } else if viewModel.widgets.isEmpty {
                Section {
                    EmptyStateView(
                        icon: "checkmark.shield.fill",
                        title: "No Turnstile Widgets",
                        message: "You haven't created any Turnstile captcha widgets in this account yet.",
                        actionTitle: "Add Widget",
                        action: { showingCreateSheet = true }
                    )
                }
                .listRowBackground(Color.clear)
            } else if viewModel.filteredWidgets.isEmpty {
                Section {
                    EmptyStateView.search(query: viewModel.searchText) {
                        viewModel.searchText = ""
                    }
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(viewModel.filteredWidgets) { widget in
                        NavigationLink(destination: TurnstileDetailView(widget: widget, viewModel: viewModel)) {
                            TurnstileWidgetRowView(widget: widget)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
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
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                ToastManager.shared.showSuccess("Widget Created", message: name)
                dismiss()
            } catch {
                ToastManager.shared.showError("Creation Failed", message: error.localizedDescription)
            }
            isSubmitting = false
        }
    }
}
