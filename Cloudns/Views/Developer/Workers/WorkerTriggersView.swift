import SwiftUI

// MARK: - WorkerTriggersView

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
                    HIGFeedback.impact(.medium)
                    Task {
                        do {
                            try await viewModel.deleteSchedule(cron: cron.cron)
                            HIGFeedback.success()
                        } catch {
                            HIGFeedback.error()
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
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(0..<3, id: \.self) { _ in
                        cronRow(WorkerSchedule(cron: "*/5 * * * *", createdOn: nil, modifiedOn: nil))
                    }
                }
                .redacted(reason: .placeholder)
            } else if !viewModel.schedules.isEmpty {
                Section(
                    header: Text("Scheduled Triggers (\(viewModel.schedules.count))"),
                    footer: Text("Cloudflare evaluates Cron triggers in UTC.")
                ) {
                    ForEach(viewModel.schedules) { schedule in
                        cronRow(schedule)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    cronToDelete = schedule
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
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.schedules.isEmpty {
                    HIGContentState(
                        .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchSchedules() } }
                        )
                    )
                } else if viewModel.schedules.isEmpty {
                    HIGContentState(
                        .empty(
                            title: "No Cron Triggers",
                            systemImage: "clock.badge.exclamationmark",
                            description: "Run this Worker on a recurring schedule with Cron syntax.",
                            actionTitle: "Add Trigger",
                            action: { showingAddCronSheet = true }
                        )
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func cronRow(_ schedule: WorkerSchedule) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.arrow.2.circlepath")
                .foregroundStyle(.blue)
                .font(.body)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.cron)
                    .font(.body.monospaced())
                    .foregroundStyle(.primary)
                
                if let modified = schedule.modifiedOn ?? schedule.createdOn {
                    Text("Configured: \(DateFormatters.formatISO8601ToDisplay(modified, style: DateFormatters.dateOnly))")
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
                            HIGFeedback.selection()
                            cronExpression = expr
                        } label: {
                            HStack {
                                Text(name)
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
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
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
                                HIGFeedback.success()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HIGFeedback.error()
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
