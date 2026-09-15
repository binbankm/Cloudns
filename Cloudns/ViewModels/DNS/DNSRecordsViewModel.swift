import Combine
import Foundation

// MARK: - DNS Record Filter Option

enum DNSRecordTypeFilter: String, CaseIterable, Identifiable, CustomStringConvertible, Sendable {
    case all = "All"
    case a = "A"
    case aaaa = "AAAA"
    case cname = "CNAME"
    case txt = "TXT"
    case mx = "MX"
    case ns = "NS"
    case srv = "SRV"
    case caa = "CAA"
    case https = "HTTPS"

    var id: String {
        rawValue
    }

    var description: String {
        rawValue
    }
}

// MARK: - DNSRecordsViewModel (Pure MVVM & UDF)

@MainActor
final class DNSRecordsViewModel: ObservableObject {
    // MARK: - Published UI States

    @Published private(set) var state: ViewState<[DNSRecord]> = .loading
    @Published var searchText: String = ""
    @Published var selectedFilter: DNSRecordTypeFilter = .all
    @Published private(set) var isRefreshing: Bool = false
    @Published var updatingRecordIds: Set<String> = []

    // MARK: - Properties & Dependencies

    let zone: Zone
    private let dnsService: DNSServiceProtocol
    private var allRecords: [DNSRecord] = []

    // MARK: - Initializer

    init(
        zone: Zone,
        dnsService: DNSServiceProtocol = DNSService.shared
    ) {
        self.zone = zone
        self.dnsService = dnsService
    }

    // MARK: - Filtered Records Computation

    var filteredRecords: [DNSRecord] {
        allRecords.filter { record in
            let matchesType: Bool
            if selectedFilter == .all {
                matchesType = true
            } else {
                matchesType = record.type.uppercased() == selectedFilter.rawValue.uppercased()
            }

            let matchesSearch: Bool
            let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if trimmedSearch.isEmpty {
                matchesSearch = true
            } else {
                let nameMatches = record.name.lowercased().contains(trimmedSearch)
                let contentMatches = (record.content ?? "").lowercased().contains(trimmedSearch)
                let commentMatches = (record.comment ?? "").lowercased().contains(trimmedSearch)
                matchesSearch = nameMatches || contentMatches || commentMatches
            }

            return matchesType && matchesSearch
        }
    }

    var recordCountSummary: String {
        "\(filteredRecords.count)"
    }

    // MARK: - Network Fetching

    func loadRecords() async {
        if !allRecords.isEmpty { return }
        state = .loading

        do {
            let (records, _) = try await dnsService.getDNSRecords(
                zoneId: zone.id,
                page: 1,
                perPage: 100,
                search: nil,
                type: nil,
                order: "name",
                direction: "asc"
            )
            allRecords = records
            updateViewStateFromRecords()
        } catch is CancellationError {
            // Silence cancellation on page switch
        } catch {
            let humaneMessage = resolveHumaneErrorMessage(for: error)
            state = .error(message: humaneMessage)
        }
    }

    func refreshRecords() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let (records, _) = try await dnsService.getDNSRecords(
                zoneId: zone.id,
                page: 1,
                perPage: 100,
                search: nil,
                type: nil,
                order: "name",
                direction: "asc"
            )
            allRecords = records
            updateViewStateFromRecords()
        } catch is CancellationError {
            // Ignore cancellation
        } catch {
            // Graceful degradation: keep existing records on screen and present gentle banner
            GentleBannerManager.shared.show(
                type: .warning,
                title: String(localized: "Refresh Failed"),
                message: String(localized: "Network connection interrupted. Please check your connection and retry.")
            )
        }
    }

    // MARK: - Record Mutating Actions

    func toggleProxy(for record: DNSRecord) async {
        guard record.proxiable == true else { return }
        let currentProxied = record.proxied ?? false
        let targetProxied = !currentProxied

        updatingRecordIds.insert(record.id)
        defer { updatingRecordIds.remove(record.id) }

        // Optimistic UI Update
        if let idx = allRecords.firstIndex(where: { $0.id == record.id }) {
            allRecords[idx].proxied = targetProxied
            updateViewStateFromRecords()
        }

        do {
            let updated = try await dnsService.updateProxyStatus(
                zoneId: zone.id,
                recordId: record.id,
                proxied: targetProxied
            )
            if let idx = allRecords.firstIndex(where: { $0.id == record.id }) {
                allRecords[idx] = updated
                updateViewStateFromRecords()
            }
            GentleHaptics.selection()
            GentleBannerManager.shared.show(
                type: targetProxied ? .success : .info,
                title: targetProxied ? String(localized: "Proxy Enabled") : String(localized: "Proxy Disabled"),
                message: targetProxied
                    ? String(localized: "Traffic routed through Cloudflare")
                    : String(localized: "Traffic routes directly to origin"),
                duration: 2.0
            )
        } catch {
            // Revert optimistic update on failure
            if let idx = allRecords.firstIndex(where: { $0.id == record.id }) {
                allRecords[idx].proxied = currentProxied
                updateViewStateFromRecords()
            }
            GentleBannerManager.shared.show(
                type: .danger,
                title: String(localized: "Operation Failed"),
                message: resolveHumaneErrorMessage(for: error)
            )
        }
    }

    func deleteRecord(id: String) async {
        updatingRecordIds.insert(id)
        defer { updatingRecordIds.remove(id) }

        let backup = allRecords
        allRecords.removeAll { $0.id == id }
        updateViewStateFromRecords()

        do {
            _ = try await dnsService.deleteDNSRecord(zoneId: zone.id, recordId: id)
            GentleHaptics.warning()
            GentleBannerManager.shared.show(
                type: .success,
                title: String(localized: "Record Deleted")
            )
        } catch {
            allRecords = backup
            updateViewStateFromRecords()
            GentleBannerManager.shared.show(
                type: .danger,
                title: String(localized: "Delete Failed"),
                message: resolveHumaneErrorMessage(for: error)
            )
        }
    }

    func insertOrUpdateRecordLocally(_ record: DNSRecord) {
        if let idx = allRecords.firstIndex(where: { $0.id == record.id }) {
            allRecords[idx] = record
        } else {
            allRecords.insert(record, at: 0)
        }
        updateViewStateFromRecords()
    }

    // MARK: - State Machine Coordinator

    private func updateViewStateFromRecords() {
        if allRecords.isEmpty {
            state = .empty(message: String(localized: "No DNS records found for this domain."))
        } else {
            state = .loaded(allRecords)
        }
    }

    private func resolveHumaneErrorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .networkError:
                return String(localized: "Network connection is unavailable. Please check your network and retry.")
            case .unauthorized:
                return String(localized: "Authentication failed. Please verify your Global API Key.")
            default:
                break
            }
        }
        if let urlError = error as? URLError {
            if urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost {
                return String(localized: "Network connection is unavailable. Please check your network and retry.")
            }
        }
        return String(localized: "Unable to load DNS records. Please pull down to retry.")
    }
}
