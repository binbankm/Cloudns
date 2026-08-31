import SwiftUI

// MARK: - TurnstileWidgetsView

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
            if !viewModel.widgets.isEmpty {
                Section {
                    ForEach(viewModel.widgets) { widget in
                        NavigationLink(destination: TurnstileDetailView(widget: widget, viewModel: viewModel)) {
                            TurnstileWidgetRowView(widget: widget)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
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
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Turnstile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
             .higToast()
        }
        .confirmationDialog("Delete Turnstile Widget", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: widgetToDelete) { widget in
            Button("Delete '\(widget.name)'", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteWidget(sitekey: widget.sitekey)
                        HIGFeedback.success()
                    } catch {
                        HIGFeedback.error()
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
            HIGContentState(.loading(message: "Loading Turnstile Widgets..."))
        } else if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.widgets.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchWidgets() }
                            }
                        )
                    )
                } else if viewModel.widgets.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Turnstile Widgets",
                            systemImage: "checkmark.shield.fill",
                            description: "You haven't created any Turnstile captcha widgets in this account yet.",
                            actionTitle: "Add Widget",
                            action: { showingCreateSheet = true }
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

// MARK: - TurnstileWidgetRowView (Inlined & Cohesive)

struct TurnstileWidgetRowView: View {
    let widget: TurnstileWidget
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(.blue)
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(widget.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text("Sitekey: \(widget.sitekey)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HIGBadge(.custom(color: .blue, text: (widget.mode ?? "managed").capitalized), isCompact: true)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - CreateTurnstileWidgetSheetView (Inlined & Cohesive)

struct CreateTurnstileWidgetSheetView: View {
    @ObservedObject var viewModel: TurnstileViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var domainsText = ""
    @State private var mode = "managed"
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    let modes = ["managed", "non-interactive", "invisible"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Widget Details")) {
                    TextField("Widget Name (e.g. Login Page)", text: $name)
                        .submitLabel(.next)
                }
                
                Section(header: Text("Allowed Domains"), footer: Text("Comma or newline separated list of hostnames (e.g. example.com, app.example.com).")) {
                    TextField("example.com, app.example.com", text: $domainsText)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Challenge Mode")) {
                    Picker("Mode", selection: $mode) {
                        ForEach(modes, id: \.self) { m in
                            Text(m.capitalized).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(verbatim: err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Turnstile Widget")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            isCreating = true
                            errorMessage = nil
                            let domains = domainsText.components(separatedBy: CharacterSet(charactersIn: ",\n "))
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }
                            do {
                                _ = try await viewModel.createWidget(
                                    name: name.trimmingCharacters(in: .whitespaces),
                                    domains: domains,
                                    mode: mode
                                )
                                HIGFeedback.success()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
                            }
                            isCreating = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }
}
