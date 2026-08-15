import SwiftUI

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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCronSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
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
                AddCronTriggerSheet(viewModel: viewModel)
            }
            .alert("Delete Cron Trigger", isPresented: $showingDeleteAlert, presenting: cronToDelete) { cron in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.deleteSchedule(cron: cron.cron)
                            ToastManager.shared.showSuccess("Cron Trigger Deleted", message: cron.cron)
                        } catch {
                            ToastManager.shared.showError("Failed to delete", message: error.localizedDescription)
                        }
                    }
                }
            } message: { cron in
                Text("Are you sure you want to delete trigger '\(cron.cron)'?")
            }
            .toastContainer()
    }
    
    @ViewBuilder
    private var contentView: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            if viewModel.isLoading && !viewModel.hasFetchedData {
                List {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
                .listStyle(.insetGrouped)
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                EmptyStateView.error(
                    message: LocalizedStringKey(errorMessage),
                    retryAction: {
                        Task { await viewModel.fetchSchedules() }
                    }
                )
            } else if viewModel.schedules.isEmpty {
                EmptyStateView(
                    icon: "clock.badge.exclamationmark",
                    title: "No Cron Triggers",
                    message: "Run scheduled Worker tasks automatically using cron syntax (e.g. every 5 minutes, daily).",
                    actionTitle: "Add Cron Trigger",
                    action: {
                        showingAddCronSheet = true
                    }
                )
            } else {
                List {
                    Section(header: Text("Scheduled Triggers (\(viewModel.schedules.count))"), footer: Text("Cloudflare evaluates Cron triggers based on UTC timezone.")) {
                        ForEach(viewModel.schedules) { schedule in
                            HStack(spacing: 12) {
                                Image(systemName: "clock.arrow.2.circlepath")
                                    .font(.title3)
                                    .foregroundColor(.purple)
                                    .frame(width: 32)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(schedule.cron)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Text(humanReadableCron(schedule.cron))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
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
                .listStyle(.insetGrouped)
            }
        }
    }
    
    private func humanReadableCron(_ cron: String) -> String {
        switch cron.trimmingCharacters(in: .whitespaces) {
        case "*/1 * * * *", "* * * * *": return "Every minute"
        case "*/5 * * * *": return "Every 5 minutes"
        case "*/10 * * * *": return "Every 10 minutes"
        case "*/15 * * * *": return "Every 15 minutes"
        case "*/30 * * * *": return "Every 30 minutes"
        case "0 * * * *": return "Every hour at minute 0"
        case "0 0 * * *": return "Every day at 00:00 UTC"
        case "0 12 * * *": return "Every day at 12:00 UTC"
        case "0 0 * * 0": return "Every Sunday at 00:00 UTC"
        case "0 0 1 * *": return "1st of every month at 00:00 UTC"
        default: return "Custom schedule expression"
        }
    }
}

// MARK: - Add Cron Trigger Sheet

private struct AddCronTriggerSheet: View {
    @ObservedObject var viewModel: WorkerTriggersViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var cronExpression = "*/5 * * * *"
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    let presets = [
        ("Every 5 minutes", "*/5 * * * *"),
        ("Every 15 minutes", "*/15 * * * *"),
        ("Every hour", "0 * * * *"),
        ("Daily at midnight (UTC)", "0 0 * * *"),
        ("Daily at noon (UTC)", "0 12 * * *"),
        ("Weekly on Sunday", "0 0 * * 0"),
        ("Monthly on 1st", "0 0 1 * *")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Cron Expression")) {
                    TextField("*/5 * * * *", text: $cronExpression)
                        .font(.body.monospacedDigit())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Common Presets")) {
                    ForEach(presets, id: \.1) { name, expr in
                        Button {
                            cronExpression = expr
                        } label: {
                            HStack {
                                Text(name)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(expr)
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(.secondary)
                                if cronExpression == expr {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Cron Trigger")
            .navigationBarTitleDisplayMode(.inline)
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
                                ToastManager.shared.showSuccess("Cron Trigger Added", message: cronExpression)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isSaving = false
                        }
                    }
                    .disabled(cronExpression.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .toastContainer()
        }
    }
}
