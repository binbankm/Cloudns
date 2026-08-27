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
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                Section {
                    ForEach(0..<3, id: \.self) { _ in
                        scheduleRow(WorkerSchedule(cron: "0 * * * *"))
                    }
                }
                .skeletonLoading(true)
            } else if !viewModel.schedules.isEmpty {
                Section(
                    header: Text("Scheduled Triggers (\(viewModel.schedules.count))"),
                    footer: Text("Cloudflare evaluates Cron triggers based on UTC timezone.")
                ) {
                    ForEach(viewModel.schedules) { schedule in
                        scheduleRow(schedule)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
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
        .centerConstrainedWidth(maxWidth: 840)
        .overlay {
            if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.schedules.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchSchedules() } }
                        )
                    )
                } else if viewModel.schedules.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "clock.badge.exclamationmark",
                            title: "No Cron Triggers",
                            message: "Run scheduled Worker tasks automatically using cron syntax (e.g. every 5 minutes, daily).",
                            actionTitle: "Add Cron Trigger",
                            action: { showingAddCronSheet = true }
                        )
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func scheduleRow(_ schedule: WorkerSchedule) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.arrow.2.circlepath")
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 32)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.cron)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.primary)
                
                Text(humanReadableCron(schedule.cron))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
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
