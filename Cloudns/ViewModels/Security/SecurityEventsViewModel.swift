import Combine
import Foundation

@MainActor
final class SecurityEventsViewModel: BaseLoadableViewModel {
    @Published var events: [SecurityEvent] = []
    @Published var searchQuery: String = ""

    var filteredEvents: [SecurityEvent] {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return events
        }
        let q = searchQuery
        return events.filter {
            $0.clientIP.localizedStandardContains(q) ||
                $0.clientCountryName.localizedStandardContains(q) ||
                $0.action.localizedStandardContains(q) ||
                $0.host.localizedStandardContains(q) ||
                ($0.clientAsn ?? "").localizedStandardContains(q)
        }
    }

    private let eventsService: SecurityEventsServiceProtocol

    init(eventsService: SecurityEventsServiceProtocol = SecurityEventsService.shared) {
        self.eventsService = eventsService
        super.init()
    }

    func fetchEvents(zoneId: String) async {
        await executeLoadingTask {
            self.events = try await self.eventsService.fetchSecurityEvents(zoneId: zoneId, limit: 50)
        }
    }
}
