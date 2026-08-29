import Foundation
import SwiftUI
import Combine

@MainActor
final class WorkerTriggersViewModel: BaseLoadableViewModel {
    let accountId: String
    let scriptName: String
    private let workerService: WorkerServiceProtocol
    
    @Published var schedules: [WorkerSchedule] = []
    
    init(accountId: String, scriptName: String, workerService: WorkerServiceProtocol = WorkerService.shared) {
        self.accountId = accountId
        self.scriptName = scriptName
        self.workerService = workerService
        super.init()
    }
    
    func fetchSchedules() async {
        await executeLoadingTask {
            self.schedules = try await self.workerService.getWorkerSchedules(accountId: self.accountId, scriptName: self.scriptName)
        }
    }
    
    func addSchedule(cron: String) async throws {
        var currentCrons = schedules.map(\.cron)
        let trimmed = cron.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !currentCrons.contains(trimmed) else { return }
        currentCrons.append(trimmed)
        try await workerService.putWorkerSchedules(accountId: accountId, scriptName: scriptName, crons: currentCrons)
        await fetchSchedules()
    }
    
    func deleteSchedule(cron: String) async throws {
        let updatedCrons = schedules.map(\.cron).filter { $0 != cron }
        try await workerService.putWorkerSchedules(accountId: accountId, scriptName: scriptName, crons: updatedCrons)
        await fetchSchedules()
    }
}
