import SwiftUI

// MARK: - TurnstileWidgetsView
// Apple HIG Compliant Cloudflare Turnstile Smart Captcha Management

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
                Section(header: Text("Active Widgets (\(viewModel.widgets.count))")) {
                    ForEach(viewModel.widgets) { widget in
                        NavigationLink(destination: TurnstileDetailView(widget: widget, viewModel: viewModel)) {
                            TurnstileWidgetRowView(widget: widget)
                        }
                        .contextMenu {
                            Button {
                                UIPasteboard.general.string = widget.sitekey
                                ToastManager.shared.showCopied("Sitekey Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy Sitekey", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                UIPasteboard.general.string = widget.name
                                ToastManager.shared.showCopied("Widget Name Copied")
                                HIGFeedback.copied()
                            } label: {
                                Label("Copy Name", systemImage: "tag")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                widgetToDelete = widget
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete Widget", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                HIGFeedback.impact(.medium)
                                widgetToDelete = widget
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(HIGColors.error)
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
                .higTouchTarget(44)
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
                        ToastManager.shared.showSuccess("Widget Deleted", icon: "trash.fill")
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
                HIGContentState(.loading(message: "Loading Turnstile Widgets…"))
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
        HStack(spacing: HIGTokens.Spacing.md) {
            ListRowIcon(icon: "checkmark.shield.fill", color: HIGColors.success)
            
            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                Text(widget.name)
                    .font(HIGTypography.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text("Sitekey: \(widget.sitekey)")
                    .font(HIGTypography.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HIGBadge(.custom(color: .blue, text: (widget.mode ?? "managed").capitalized), isCompact: true)
        }
        .padding(.vertical, HIGTokens.Spacing.xxs)
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
                        .font(HIGTypography.body)
                        .submitLabel(.next)
                }
                
                Section(header: Text("Allowed Domains"), footer: Text("Comma or newline separated list of hostnames (e.g. example.com, app.example.com).")) {
                    TextField("example.com, app.example.com", text: $domainsText)
                        .font(HIGTypography.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
                
                Section(header: Text("Verification Mode")) {
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
                            .font(HIGTypography.caption)
                            .foregroundStyle(HIGColors.error)
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
                        .higTouchTarget(44)
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
                                ToastManager.shared.showSuccess("Turnstile Widget Created", icon: "checkmark.shield.fill")
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
                            }
                            isCreating = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || domainsText.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                    .higTouchTarget(44)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }
}
