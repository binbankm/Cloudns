import SwiftUI

// MARK: - WorkerTriggersView
// Apple HIG Compliant Cloudflare Worker Scheduled Cron Triggers

struct WorkerTriggersView: View {
    let accountId: String
    let scriptName: String
    
    @StateObject private var viewModel: WorkerTriggersViewModel
    @State private var showingAddCronSheet = false
    @State private var cronToDelete: WorkerSchedule?
    @State private var showingDeleteAlert = false
    
    init(accountId: String, scriptName: String) {
        self.accountId = accountId
        self.scriptName = scriptName
        _viewModel = StateObject(wrappedValue: WorkerTriggersViewModel(accountId: accountId, scriptName: scriptName))
    }
    
    var body: some View {
        contentView
            .navigationTitle("Cron Triggers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddCronSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Cron Trigger")
                }
            }
            .refreshable {
                await viewModel.fetchSchedules()
            }
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchSchedules()
                }
            }
            .sheet(isPresented: $showingAddCronSheet) {
                AddCronTriggerSheetView(viewModel: viewModel)
            }
            .confirmationDialog("Delete Cron Trigger", isPresented: $showingDeleteAlert, titleVisibility: .visible, presenting: cronToDelete) { cron in
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteSchedule(cron: cron.cron)
                            ToastManager.shared.showSuccess("Cron Trigger Deleted", icon: "trash.fill")
                            HapticManager.notification(.success)
                        } catch {
                            ToastManager.shared.showError("Failed to Delete Trigger")
                            HapticManager.notification(.error)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { cron in
                Text("Are you sure you want to delete trigger '\(cron.cron)'?")
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if !viewModel.schedules.isEmpty {
                Section(
                    header: Text("Scheduled Triggers (\(viewModel.schedules.count))"),
                    footer: Text("Cloudflare evaluates Cron triggers in UTC.")
                ) {
                    ForEach(viewModel.schedules) { schedule in
                        cronRow(schedule)
                            .contextMenu {
                                Button {
                                    copyToClipboard(schedule.cron, toast: "Cron Expression Copied")
                                } label: {
                                    Label("Copy Cron Expression", systemImage: "doc.on.doc")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    cronToDelete = schedule
                                    showingDeleteAlert = true
                                    HapticManager.impact(.medium)
                                } label: {
                                    Label("Delete Trigger", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    cronToDelete = schedule
                                    showingDeleteAlert = true
                                    HapticManager.impact(.medium)
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
            isLoading: viewModel.isLoading && !viewModel.hasFetchedData,
            loadingMessage: "Loading Triggers…",
            isEmpty: viewModel.hasFetchedData && viewModel.schedules.isEmpty,
            emptyTitle: "No Cron Triggers",
            emptySystemImage: "clock.badge.exclamationmark",
            emptyDescription: "Run this Worker on a recurring schedule with Cron syntax.",
            emptyActionTitle: "Add Trigger",
            emptyAction: { showingAddCronSheet = true },
            errorMessage: (viewModel.hasFetchedData && viewModel.schedules.isEmpty) ? viewModel.errorMessage.map { LocalizedStringKey($0) } : nil,
            retryAction: { Task { await viewModel.fetchSchedules() } }
        )
    }
    
    @ViewBuilder
    private func cronRow(_ schedule: WorkerSchedule) -> some View {
        HStack(spacing: 12) {
            ListRowIcon(icon: "clock.arrow.2.circlepath", color: .purple)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.cron)
                    .font(.body.monospaced())
                    .foregroundStyle(.primary)
                
                if let modified = schedule.modifiedOn ?? schedule.createdOn, let date = DateFormatters.parseISO8601(modified) {
                    Text("Configured: \(date.displayFormatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - AddCronTriggerSheetView (Inlined & Cohesive)

struct AddCronTriggerSheetView: View {
    @ObservedObject var viewModel: WorkerTriggersViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var cronExpression = "*/15 * * * *"
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private let presets = [
        ("Every minute", "* * * * *"),
        ("Every 5 minutes", "*/5 * * * *"),
        ("Every 15 minutes", "*/15 * * * *"),
        ("Every hour", "0 * * * *"),
        ("Daily at midnight UTC", "0 0 * * *"),
        ("Weekly on Sunday", "0 0 * * 0")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Cron Expression"), footer: Text("Standard 5-segment cron format: minute hour day-of-month month day-of-week (UTC).")) {
                    TextField("*/15 * * * *", text: $cronExpression)
                        .font(.body.monospaced())
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Common Presets")) {
                    ForEach(presets, id: \.1) { name, expr in
                        Button {
                            HapticManager.selection()
                            cronExpression = expr
                        } label: {
                            HStack {
                                Text(name)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(expr)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                if let err = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(verbatim: err)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Cron Trigger")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            do {
                                try await viewModel.addSchedule(cron: cronExpression)
                                ToastManager.shared.showSuccess("Cron Trigger Added", icon: "checkmark.circle.fill")
                                HapticManager.notification(.success)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.notification(.error)
                            }
                            isSaving = false
                        }
                    }
                    .disabled(cronExpression.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
