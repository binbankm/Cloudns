import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
class DNSRecordsViewModel: ObservableObject {
    @Published var records: [DNSRecord] = []
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    @Published var totalCount: Int = 0
    
    // Removed DNSSEC
    
    @Published var searchQuery: String = ""
    @Published var sortOption: String = "name"
    
    private var cancellables = Set<AnyCancellable>()
    
    private var currentPage = 1
    private var totalPages = 1
    var canLoadMore: Bool {
        currentPage < totalPages
    }
    
    private let zoneId: String
    
    init(zoneId: String) {
        self.zoneId = zoneId
        
        $searchQuery
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                Task {
                    await self?.fetchRecords(isRefresh: true)
                }
            }
            .store(in: &cancellables)
            
        $sortOption
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                Task {
                    await self?.fetchRecords(isRefresh: true)
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
        
        isLoading = true
        errorMessage = nil
        
        do {
            let (newRecords, resultInfo) = try await CloudflareAPIClient.shared.getDNSRecords(
                zoneId: zoneId,
                page: currentPage,
                search: searchQuery,
                order: sortOption,
                direction: sortOption == "name" ? "asc" : "desc" // Or let user choose direction
            )
            
            if isRefresh {
                self.records = newRecords
            } else {
                self.records.append(contentsOf: newRecords)
            }
            
            if let info = resultInfo {
                self.totalPages = info.totalPages
                self.currentPage = info.page
                self.totalCount = info.totalCount
            }
            
            self.currentPage += 1
            self.hasFetchedData = true
        } catch {
            self.errorMessage = "Failed to fetch DNS records: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    

    
    func deleteRecords(withIds ids: Set<String>) {
        guard !ids.isEmpty else { return }
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.warning)
        
        records.removeAll { ids.contains($0.id) }
        totalCount = max(0, totalCount - ids.count)
        
        Task {
            do {
                try await CloudflareAPIClient.shared.batchDNSRecords(zoneId: zoneId, deletes: Array(ids))
            } catch {
                self.errorMessage = "Failed to batch delete records: \(error.localizedDescription)"
                await self.fetchRecords(isRefresh: true)
            }
        }
    }
    
    func deleteRecord(at offsets: IndexSet) {
        let recordsToDelete = offsets.map { records[$0] }
        
        // impact
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.warning)
        
        records.remove(atOffsets: offsets)
        
        Task {
            do {
                let idsToDelete = recordsToDelete.map { $0.id }
                try await CloudflareAPIClient.shared.batchDNSRecords(zoneId: zoneId, deletes: idsToDelete)
                DispatchQueue.main.async {
                    self.totalCount = max(0, self.totalCount - idsToDelete.count)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to batch delete records: \(error.localizedDescription)"
                    // Re-fetch to restore correct state
                    Task {
                        await self.fetchRecords(isRefresh: true)
                    }
                }
            }
        }
    }
    
    func addRecord(payload: DNSRecordPayload) async throws {
        let newRecord = try await CloudflareAPIClient.shared.createDNSRecord(zoneId: zoneId, payload: payload)
        self.records.insert(newRecord, at: 0)
        self.totalCount += 1
    }
    
    func updateRecord(recordId: String, payload: DNSRecordPayload) async throws {
        let updatedRecord = try await CloudflareAPIClient.shared.updateDNSRecord(zoneId: zoneId, recordId: recordId, payload: payload)
        if let index = self.records.firstIndex(where: { $0.id == recordId }) {
            self.records[index] = updatedRecord
        }
    }
    
    func deleteRecord(recordId: String) async throws {
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.warning)
        try await CloudflareAPIClient.shared.deleteDNSRecord(zoneId: zoneId, recordId: recordId)
        self.records.removeAll { $0.id == recordId }
        self.totalCount = max(0, self.totalCount - 1)
    }
    
    func exportRecords() async throws -> URL {
        isLoading = true
        defer { isLoading = false }
        return try await CloudflareAPIClient.shared.exportDNSRecords(zoneId: zoneId)
    }
    
    func importRecords(fileURL: URL) async throws {
        isLoading = true
        errorMessage = nil
        do {
            try await CloudflareAPIClient.shared.importDNSRecords(zoneId: zoneId, fileURL: fileURL)
            await fetchRecords(isRefresh: true)
        } catch {
            errorMessage = "Failed to import DNS records: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
