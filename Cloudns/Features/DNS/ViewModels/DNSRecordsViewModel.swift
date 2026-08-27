import Foundation
import Combine
import SwiftUI

@MainActor
final class DNSRecordsViewModel: BaseLoadableViewModel {
    @Published var records: [DNSRecord] = []
    @Published var totalCount: Int = 0
    
    // Removed DNSSEC
    
    @Published var searchQuery: String = ""
    @Published var sortOption: String = "name"
    
    var filteredRecords: [DNSRecord] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return records
        }
        return records.filter { record in
            record.name.localizedStandardContains(trimmed) ||
            (record.content ?? "").localizedStandardContains(trimmed) ||
            record.type.localizedStandardContains(trimmed) ||
            (record.comment ?? "").localizedStandardContains(trimmed)
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    
    private var currentPage = 1
    private var totalPages = 1
    var canLoadMore: Bool {
        currentPage < totalPages
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
                guard let self = self else { return }
                self.searchTask?.cancel()
                self.searchTask = Task {
                    await self.fetchRecords(isRefresh: true)
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchRecords(isRefresh: Bool = false) async {
        if isRefresh {
            currentPage = 1
        }
        
        guard !isLoading else { return }
        if !isRefresh && !canLoadMore && !records.isEmpty { return }
        
        await executeLoadingTask(clearError: isRefresh) {
            let (newRecords, resultInfo) = try await self.dnsService.getDNSRecords(
                zoneId: self.zoneId,
                page: self.currentPage,
                perPage: 50,
                search: nil,
                type: nil,
                order: self.sortOption,
                direction: self.sortOption == "name" ? "asc" : "desc"
            )
            
            if isRefresh {
                self.records = newRecords
            } else {
                self.records.append(contentsOf: newRecords)
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
        HapticManager.notification(.warning)
        
        records.removeAll { ids.contains($0.id) }
        totalCount = max(0, totalCount - ids.count)
        
        Task {
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
        let idsToDelete = recordsToDelete.map { $0.id }
        
        HapticManager.notification(.warning)
        records.remove(atOffsets: offsets)
        self.totalCount = max(0, self.totalCount - idsToDelete.count)
        
        Task {
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
        self.records.insert(newRecord, at: 0)
        self.totalCount += 1
    }
    
    func updateRecord(recordId: String, payload: DNSRecordPayload) async throws {
        let updatedRecord = try await dnsService.updateDNSRecord(zoneId: zoneId, recordId: recordId, payload: payload)
        if let index = self.records.firstIndex(where: { $0.id == recordId }) {
            self.records[index] = updatedRecord
        }
    }
    
    func toggleProxy(for record: DNSRecord) async {
        guard record.proxiable == true else { return }
        let currentProxied = record.proxied ?? false
        let newProxied = !currentProxied
        
        // Optimistic UI update
        if let idx = records.firstIndex(where: { $0.id == record.id }) {
            var updated = records[idx]
            updated.proxied = newProxied
            records[idx] = updated
        }
        
        HapticManager.impact(.medium)
        
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
            }
            CloudnsToastManager.shared.showSuccess(
                newProxied ? "CDN Proxy Enabled" : "DNS Only Enabled",
                message: "\(record.name) (\(record.type))"
            )
        } catch {
            // Rollback on error
            if let idx = records.firstIndex(where: { $0.id == record.id }) {
                var rollback = records[idx]
                rollback.proxied = currentProxied
                records[idx] = rollback
            }
            CloudnsToastManager.shared.showError("Failed to update proxy status", message: error.localizedDescription)
        }
    }
    
    func deleteRecord(recordId: String) async throws {
        HapticManager.notification(.warning)
        _ = try await dnsService.deleteDNSRecord(zoneId: zoneId, recordId: recordId)
        self.records.removeAll { $0.id == recordId }
        self.totalCount = max(0, self.totalCount - 1)
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
}
