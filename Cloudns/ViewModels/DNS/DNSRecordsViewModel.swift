import Combine
import Foundation

// MARK: - Supporting Types

enum DNSSortOption: String, CaseIterable {
    case name
    case type

    var apiValue: String {
        rawValue
    }

    var direction: String {
        self == .name ? "asc" : "desc"
    }

    var displayName: String {
        switch self {
        case .name: "Name (A to Z)"
        case .type: "Record Type"
        }
    }
}

enum DNSProxyFilter: String, CaseIterable {
    case all = "ALL"
    case proxied = "PROXIED"
    case dnsOnly = "DNS_ONLY"

    var displayName: String {
        switch self {
        case .all: "All Statuses"
        case .proxied: "Proxied (Orange Cloud)"
        case .dnsOnly: "DNS Only (Grey Cloud)"
        }
    }
}

// MARK: - ViewModel

@MainActor
final class DNSRecordsViewModel: BaseLoadableViewModel {
    @Published var records: [DNSRecord] = []
    @Published var totalCount: Int = 0

    @Published var searchQuery: String = ""
    @Published var sortOption: DNSSortOption = .name
    @Published var selectedType: String = "ALL"
    @Published var selectedProxyFilter: DNSProxyFilter = .all

    static let supportedRecordTypes: [String] = ["A", "AAAA", "CNAME", "TXT", "MX", "NS", "PTR", "SRV", "CAA"]

    var isFiltered: Bool {
        selectedType != "ALL" || selectedProxyFilter != .all
    }

    func resetFilters() {
        selectedType = "ALL"
        selectedProxyFilter = .all
    }

    var filteredRecords: [DNSRecord] {
        var result = records
        if selectedType != "ALL" {
            result = result.filter { $0.type.uppercased() == selectedType.uppercased() }
        }
        switch selectedProxyFilter {
        case .proxied:
            result = result.filter { $0.proxied == true }
        case .dnsOnly:
            result = result.filter { $0.proxied != true }
        case .all:
            break
        }
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return result
        }
        return result.filter { record in
            record.name.localizedStandardContains(trimmed) ||
                (record.content ?? "").localizedStandardContains(trimmed) ||
                record.type.localizedStandardContains(trimmed) ||
                (record.comment ?? "").localizedStandardContains(trimmed)
        }
    }

    /// Grouped record types for sectioned list display (moved from View layer)
    var groupedRecordTypes: [String] {
        Array(Set(filteredRecords.map(\.type))).sorted()
    }

    func records(for type: String) -> [DNSRecord] {
        filteredRecords.filter { $0.type == type }
    }

    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?

    private var currentPage = 1
    private var totalPages = 1
    var canLoadMore: Bool {
        currentPage <= totalPages
    }

    private let zoneId: String
    private let dnsService: DNSServiceProtocol

    init(zoneId: String, dnsService: DNSServiceProtocol = DNSService.shared) {
        self.zoneId = zoneId
        self.dnsService = dnsService
        super.init()

        $sortOption
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                searchTask?.cancel()
                searchTask = Task {
                    await self.fetchRecords(isRefresh: true)
                }
            }
            .store(in: &cancellables)

        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func fetchRecords(isRefresh: Bool = false) async {
        if isRefresh {
            currentPage = 1
        }

        let scopedKey = SWRCacheStore.accountScopedKey("dns_records_\(zoneId)")

        if !hasFetchedData, !isRefresh {
            if let cached = await SWRCacheStore.shared.get(forKey: scopedKey, as: [DNSRecord].self), !cached.isEmpty {
                records = cached
                totalCount = cached.count
                hasFetchedData = true
            }
        }

        guard !isLoading else { return }

        await executeLoadingTask(clearError: isRefresh) {
            let (newRecords, resultInfo) = try await self.dnsService.getDNSRecords(
                zoneId: self.zoneId,
                page: self.currentPage,
                perPage: 50,
                search: nil,
                type: nil,
                order: self.sortOption.apiValue,
                direction: self.sortOption.direction
            )

            if isRefresh || self.currentPage == 1 {
                self.records = newRecords
                await SWRCacheStore.shared.set(newRecords, forKey: scopedKey)
            } else {
                self.records.append(contentsOf: newRecords)
                await SWRCacheStore.shared.set(self.records, forKey: scopedKey)
            }

            if let info = resultInfo {
                self.totalPages = info.totalPages
                self.currentPage = info.page + 1
                self.totalCount = info.totalCount
            } else {
                self.currentPage += 1
            }
            self.hasFetchedData = true
        }
    }

    func deleteRecords(withIds ids: Set<String>) {
        guard !ids.isEmpty else { return }
        records.removeAll { ids.contains($0.id) }
        totalCount = max(0, totalCount - ids.count)

        Task {
            let scopedKey = SWRCacheStore.accountScopedKey("dns_records_\(zoneId)")
            await SWRCacheStore.shared.set(self.records, forKey: scopedKey)
            do {
                try await self.dnsService.batchDNSRecords(zoneId: self.zoneId, deletes: Array(ids))
            } catch {
                self.errorMessage = "Failed to batch delete records: \(error.localizedDescription)"
                await self.fetchRecords(isRefresh: true)
            }
        }
    }

    func deleteRecord(at offsets: IndexSet) {
        let recordsToDelete = offsets.map { records[$0] }
        let idsToDelete = recordsToDelete.map(\.id)

        records.remove(atOffsets: offsets)
        totalCount = max(0, totalCount - idsToDelete.count)

        Task {
            let scopedKey = SWRCacheStore.accountScopedKey("dns_records_\(zoneId)")
            await SWRCacheStore.shared.set(self.records, forKey: scopedKey)
            do {
                try await self.dnsService.batchDNSRecords(zoneId: self.zoneId, deletes: idsToDelete)
            } catch {
                self.errorMessage = "Failed to batch delete records: \(error.localizedDescription)"
                await self.fetchRecords(isRefresh: true)
            }
        }
    }

    func addRecord(payload: DNSRecordPayload) async throws {
        let newRecord = try await dnsService.createDNSRecord(zoneId: zoneId, payload: payload)
        records.insert(newRecord, at: 0)
        totalCount += 1
        let scopedKey = SWRCacheStore.accountScopedKey("dns_records_\(zoneId)")
        await SWRCacheStore.shared.set(records, forKey: scopedKey)
    }

    func updateRecord(recordId: String, payload: DNSRecordPayload) async throws {
        let updatedRecord = try await dnsService.updateDNSRecord(zoneId: zoneId, recordId: recordId, payload: payload)
        if let index = records.firstIndex(where: { $0.id == recordId }) {
            records[index] = updatedRecord
            let scopedKey = SWRCacheStore.accountScopedKey("dns_records_\(zoneId)")
            await SWRCacheStore.shared.set(records, forKey: scopedKey)
        }
    }

    /// Toggles the Cloudflare proxy status for a record.
    /// Returns whether the new proxied state is enabled, so the View can trigger haptics/toasts.
    @discardableResult
    func toggleProxy(for record: DNSRecord) async -> Bool? {
        guard record.proxiable == true else { return nil }
        let currentProxied = record.proxied ?? false
        let newProxied = !currentProxied
        let scopedKey = SWRCacheStore.accountScopedKey("dns_records_\(zoneId)")

        // Optimistic UI update
        if let idx = records.firstIndex(where: { $0.id == record.id }) {
            var updated = records[idx]
            updated.proxied = newProxied
            records[idx] = updated
            await SWRCacheStore.shared.set(records, forKey: scopedKey)
        }

        do {
            let payload = DNSRecordPayload(
                type: record.type,
                name: record.name,
                content: record.content,
                ttl: record.ttl,
                proxied: newProxied,
                priority: record.priority,
                comment: record.comment,
                data: record.data
            )
            let updatedRecord = try await dnsService.updateDNSRecord(zoneId: zoneId, recordId: record.id, payload: payload)
            if let idx = records.firstIndex(where: { $0.id == record.id }) {
                records[idx] = updatedRecord
                await SWRCacheStore.shared.set(records, forKey: scopedKey)
            }
            return newProxied
        } catch {
            // Rollback on error
            if let idx = records.firstIndex(where: { $0.id == record.id }) {
                var rollback = records[idx]
                rollback.proxied = currentProxied
                records[idx] = rollback
                await SWRCacheStore.shared.set(records, forKey: scopedKey)
            }
            errorMessage = "Failed to Update Proxy Status"
            return nil
        }
    }

    func deleteRecord(recordId: String) async throws {
        _ = try await dnsService.deleteDNSRecord(zoneId: zoneId, recordId: recordId)
        records.removeAll { $0.id == recordId }
        totalCount = max(0, totalCount - 1)
        let scopedKey = SWRCacheStore.accountScopedKey("dns_records_\(zoneId)")
        await SWRCacheStore.shared.set(records, forKey: scopedKey)
    }

    func exportRecords() async throws -> URL {
        isLoading = true
        defer { isLoading = false }
        return try await dnsService.exportDNSRecords(zoneId: zoneId)
    }

    func importRecords(fileURL: URL) async throws {
        isLoading = true
        errorMessage = nil
        do {
            try await dnsService.importDNSRecords(zoneId: zoneId, fileURL: fileURL)
            await fetchRecords(isRefresh: true)
        } catch {
            errorMessage = "Failed to import DNS records: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func scanRecords() async -> Int? {
        do {
            let res = try await dnsService.scanDNSRecords(zoneId: zoneId)
            await fetchRecords(isRefresh: true)
            return res
        } catch {
            return nil
        }
    }
}
