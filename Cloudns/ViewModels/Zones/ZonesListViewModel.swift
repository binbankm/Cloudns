import Combine
import Foundation

// MARK: - Zone Status Filter

enum ZoneStatusFilter: String, CaseIterable, Identifiable, CustomStringConvertible, Sendable {
    case all = "All"
    case active = "Active"
    case pending = "Pending"
    case paused = "Paused"

    var id: String {
        rawValue
    }

    var description: String {
        rawValue
    }
}

// MARK: - ZonesListViewModel (Pure MVVM & UDF)

@MainActor
final class ZonesListViewModel: ObservableObject {
    // MARK: - Published UI States

    @Published private(set) var state: ViewState<[Zone]> = .idle
    @Published var searchText: String = ""
    @Published var selectedFilter: ZoneStatusFilter = .all
    @Published private(set) var isRefreshing: Bool = false

    // MARK: - Dependencies

    private let zoneService: ZoneServiceProtocol
    private let accountManager: AccountManager
    private var cancellables = Set<AnyCancellable>()
    private var allZones: [Zone] = []

    // MARK: - Initializer

    init(
        zoneService: ZoneServiceProtocol = ZoneService.shared,
        accountManager: AccountManager = AccountManager.shared
    ) {
        self.zoneService = zoneService
        self.accountManager = accountManager
        setupAccountSwitchListener()
    }

    // MARK: - Computed Presentation Properties

    var filteredZones: [Zone] {
        allZones.filter { zone in
            let matchesSearch: Bool = {
                let query = searchText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
                if query.isEmpty {
                    return true
                }
                return zone.name.lowercased().contains(query)
            }()

            let matchesFilter: Bool = switch selectedFilter {
            case .all:
                true
            case .active:
                zone.isActive
            case .pending:
                zone.zoneStatus == .pending || zone.zoneStatus == .initializing
            case .paused:
                zone.paused
            }

            return matchesSearch && matchesFilter
        }
    }

    var totalZonesCount: Int {
        allZones.count
    }

    var activeZonesCount: Int {
        allZones.filter(\.isActive).count
    }

    var pendingZonesCount: Int {
        allZones.filter { $0.zoneStatus == .pending || $0.zoneStatus == .initializing }.count
    }

    var pausedZonesCount: Int {
        allZones.filter(\.paused).count
    }

    var healthPercentage: Double {
        guard totalZonesCount > 0 else { return 100.0 }
        return (Double(activeZonesCount) / Double(totalZonesCount)) * 100.0
    }

    // MARK: - Actions

    func loadZones() async {
        guard !state.isLoading else { return }
        state = .loading

        do {
            let (zones, _) = try await zoneService.getZones(page: 1, perPage: 50, name: nil, status: nil)
            guard !Task.isCancelled else { return }
            allZones = zones

            if zones.isEmpty {
                state = .empty(message: "No domains found in this account.")
            } else {
                state = .loaded(zones)
            }
        } catch {
            guard !Task.isCancelled, !(error is CancellationError) else { return }
            let humaneMessage = resolveHumaneErrorMessage(for: error)
            state = .error(message: humaneMessage)
        }
    }

    func refreshZones() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let (zones, _) = try await zoneService.getZones(page: 1, perPage: 50, name: nil, status: nil)
            guard !Task.isCancelled else { return }
            allZones = zones

            if zones.isEmpty {
                state = .empty(message: "No domains found in this account.")
            } else {
                state = .loaded(zones)
            }
        } catch {
            guard !Task.isCancelled, !(error is CancellationError) else { return }
            let humaneMessage = resolveHumaneErrorMessage(for: error)
            if !allZones.isEmpty {
                GentleBannerManager.shared.show(
                    type: .warning,
                    title: "Refresh Failed",
                    message: humaneMessage
                )
            } else {
                state = .error(message: humaneMessage)
            }
        }
    }

    func togglePause(for zone: Zone) async {
        let newPaused = !zone.paused
        do {
            try await zoneService.updateZoneStatus(zoneId: zone.id, paused: newPaused)
            if let index = allZones.firstIndex(where: { $0.id == zone.id }) {
                let updated = Zone(
                    account: zone.account,
                    id: zone.id,
                    name: zone.name,
                    status: zone.status,
                    paused: newPaused,
                    type: zone.type,
                    plan: zone.plan,
                    developmentMode: zone.developmentMode,
                    nameServers: zone.nameServers,
                    originalNameServers: zone.originalNameServers,
                    originalRegistrar: zone.originalRegistrar,
                    originalDnshost: zone.originalDnshost,
                    modifiedOn: zone.modifiedOn,
                    createdOn: zone.createdOn,
                    activatedOn: zone.activatedOn
                )
                allZones[index] = updated
                state = .loaded(allZones)
            }
        } catch {
            let humaneMessage = resolveHumaneErrorMessage(for: error)
            GentleBannerManager.shared.show(
                type: .warning,
                title: "Operation Failed",
                message: humaneMessage
            )
        }
    }

    /// Adds a newly created zone to the active list immediately
    func addZoneLocally(_ zone: Zone) {
        if !allZones.contains(where: { $0.id == zone.id }) {
            allZones.insert(zone, at: 0)
        }
        state = .loaded(allZones)
        GentleBannerManager.shared.show(
            type: .success,
            title: "Domain Added",
            message: String(localized: "\(zone.name) has been successfully added.")
        )
    }

    /// Deletes a zone by id with graceful UI degradation
    func deleteZone(id: String) async throws {
        do {
            _ = try await zoneService.deleteZone(zoneId: id)
            allZones.removeAll { $0.id == id }
            if allZones.isEmpty {
                state = .empty(message: String(localized: "No domains found in this account."))
            } else {
                state = .loaded(allZones)
            }
            GentleHaptics.warning()
            GentleBannerManager.shared.show(
                type: .info,
                title: "Domain Removed",
                message: String(localized: "Domain configuration was deleted from Cloudflare.")
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            let humaneMessage = resolveHumaneErrorMessage(for: error)
            GentleBannerManager.shared.show(
                type: .danger,
                title: "Failed to Remove Domain",
                message: humaneMessage
            )
            throw error
        }
    }

    // MARK: - Private Helpers

    private func setupAccountSwitchListener() {
        NotificationCenter.default
            .publisher(for: .accountSwitched)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.loadZones()
                }
            }
            .store(in: &cancellables)
    }

    private func resolveHumaneErrorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized:
                return String(localized: "Authentication failed. Please verify your Global API Key.")
            case .networkError:
                return String(localized: "Network connection interrupted. Please check your connection and retry.")
            case let .cloudflareError(message):
                return message
            default:
                return String(localized: "Unable to load domains at this time. Please pull to refresh.")
            }
        }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return String(localized: "Network connection is unavailable. Please check your network and retry.")
        }
        return String(localized: "Unable to load domains. Please pull down to retry.")
    }
}
