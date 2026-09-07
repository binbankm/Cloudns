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
                Section("Active Widgets (\(viewModel.widgets.count))") {
                    ForEach(viewModel.widgets) { widget in
                        NavigationLink(destination: TurnstileDetailView(widget: widget, viewModel: viewModel)) {
                            TurnstileWidgetRowView(widget: widget)
                        }
                        .contextMenu {
                            Button {
                                copyToClipboard(widget.sitekey, toast: "Sitekey Copied")
                            } label: {
                                Label("Copy Sitekey", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                copyToClipboard(widget.name, toast: "Widget Name Copied")
                            } label: {
                                Label("Copy Name", systemImage: "tag")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                widgetToDelete = widget
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete Widget", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                HapticManager.impact(.medium)
                                widgetToDelete = widget
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading Turnstile Widgets…",
            isEmpty: viewModel.hasFetchedData && viewModel.widgets.isEmpty && viewModel.errorMessage == nil,
            emptyTitle: "No Turnstile Widgets",
            emptyDescription: "You haven't created any Turnstile captcha widgets in this account yet.",
            emptyActionTitle: "Add Widget",
            emptyAction: { showingCreateSheet = true },
            errorMessage: viewModel.errorMessage.map { LocalizedStringKey($0) },
            retryAction: { Task { await viewModel.fetchWidgets() } }
        )
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
        }
        .confirmationDialog("Delete Turnstile Widget", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: widgetToDelete) { widget in
            Button("Delete '\(widget.name)'", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteWidget(sitekey: widget.sitekey)
                        ToastManager.shared.showSuccess("Widget Deleted", icon: "trash.fill")
                        HapticManager.notification(.success)
                    } catch {
                        HapticManager.notification(.error)
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
            ListRowIcon(icon: "checkmark.shield.fill", color: .green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(widget.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text("Sitekey: \(widget.sitekey)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text((widget.mode ?? "managed").capitalized)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.blue)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.blue.opacity(0.12)))
        }
        .padding(.vertical, 2)
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
                Section("Widget Details") {
                    TextField("Widget Name (e.g. Login Page)", text: $name)
                        .font(.body)
                        .submitLabel(.next)
                }
                
                Section {
                    TextField("example.com, app.example.com", text: $domainsText)
                        .font(.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                } header: {
                    Text("Allowed Domains")
                } footer: {
                    Text("Comma or newline separated list of hostnames (e.g. example.com, app.example.com).")
                }
                
                Section("Verification Mode") {
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
                                HapticManager.notification(.success)
                                ToastManager.shared.showSuccess("Turnstile Widget Created", icon: "checkmark.shield.fill")
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.notification(.error)
                            }
                            isCreating = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || domainsText.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
            .interactiveDismissDisabled(isCreating)
        }
    }
}
