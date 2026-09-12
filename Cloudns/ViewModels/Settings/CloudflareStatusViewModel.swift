import Combine
import Foundation

@MainActor
final class CloudflareStatusViewModel: BaseLoadableViewModel {
    @Published var summary: CFStatusSummary?
    @Published var searchQuery: String = ""

    // MARK: - Component Classification

    var allComponents: [CFComponentItem] {
        summary?.components ?? []
    }

    var issuesComponents: [CFComponentItem] {
        allComponents.filter { $0.status.lowercased() != "operational" }
    }

    var servicesComponents: [CFComponentItem] {
        allComponents.filter { !isDataCenter($0.name) }
    }

    var popsComponents: [CFComponentItem] {
        allComponents.filter { isDataCenter($0.name) }
    }

    func filteredComponents(for tab: Int, searchQuery: String) -> [CFComponentItem] {
        let base: [CFComponentItem] = switch tab {
        case 0: issuesComponents
        case 1: servicesComponents
        case 2: popsComponents
        default: allComponents
        }
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return base }
        return base.filter {
            $0.name.lowercased().contains(q) ||
                (extractIATA($0.name)?.lowercased().contains(q) ?? false)
        }
    }

    // MARK: - Private Helpers

    private func isDataCenter(_ name: String) -> Bool {
        name.contains(" - (") || (name.contains(" (") && name.hasSuffix(")"))
    }

    func extractIATA(_ name: String) -> String? {
        if let match = name.range(of: #"\([A-Z]{3,4}\)"#, options: .regularExpression) {
            return String(name[match])
        }
        return nil
    }

    private let statusService: CloudflareStatusServiceProtocol

    init(statusService: CloudflareStatusServiceProtocol = CloudflareStatusService.shared) {
        self.statusService = statusService
        super.init()
    }

    func fetchStatus() async {
        await executeLoadingTask {
            let res = try await self.statusService.fetchCloudflareStatus()
            self.summary = res
            self.hasFetchedData = true
            let snap = CFStatusWidgetSnapshot(
                indicator: res.status?.indicator ?? "none",
                description: res.status?.description ?? String(localized: "All Systems Operational"),
                activeIncidentsCount: res.incidents?.count ?? 0,
                latestIncidentTitle: res.incidents?.first?.name,
                lastUpdated: Date()
            )
            WidgetDataStore.shared.saveStatusSnapshot(snap)
        }
    }
}
