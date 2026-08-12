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
    
    // DNSSEC
    @Published var dnssec: DNSSEC?
    @Published var isDNSSECLoading = false
    
    private var currentPage = 1
    private var totalPages = 1
    var canLoadMore: Bool {
        currentPage < totalPages
    }
    
    private let zoneId: String
    
    init(zoneId: String) {
        self.zoneId = zoneId
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
            let (newRecords, resultInfo) = try await CloudflareAPIClient.shared.getDNSRecords(zoneId: zoneId, page: currentPage)
            
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
    
    func fetchDNSSEC() async {
        guard !isDNSSECLoading else { return }
        isDNSSECLoading = true
        do {
            self.dnssec = try await CloudflareAPIClient.shared.getDNSSEC(zoneId: zoneId)
        } catch {
            // Silently fail DNSSEC fetch to not interrupt the main DNS flow
            print("Failed to fetch DNSSEC: \(error)")
        }
        isDNSSECLoading = false
    }
    
    func toggleDNSSEC() async {
        guard let current = dnssec else { return }
        isDNSSECLoading = true
        
        // impact
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        do {
            let isActiveOrPending = current.status == "active" || current.status == "pending"
            let targetStatus = isActiveOrPending ? "disabled" : "active"
            try await CloudflareAPIClient.shared.updateDNSSEC(zoneId: zoneId, status: targetStatus)
            
            // Re-fetch after update
            self.dnssec = try await CloudflareAPIClient.shared.getDNSSEC(zoneId: zoneId)
        } catch {
            self.errorMessage = "Failed to update DNSSEC: \(error.localizedDescription)"
        }
        
        isDNSSECLoading = false
    }
    
    func deleteRecord(at offsets: IndexSet) {
        let recordsToDelete = offsets.map { records[$0] }
        
        // impact
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.warning)
        
        records.remove(atOffsets: offsets)
        
        Task {
            for record in recordsToDelete {
                do {
                    try await CloudflareAPIClient.shared.deleteDNSRecord(zoneId: zoneId, recordId: record.id)
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to delete \(record.name): \(error.localizedDescription)"
                        // Optionally re-insert the record
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
}
