import Foundation
import SwiftUI
import Combine

nonisolated struct AggregatedWorkerDataPoint: Codable, Identifiable, Equatable, Sendable {
    var id: String { timestamp }
    let timestamp: String
    let date: Date
    let requests: Int
    let errors: Int
    let subrequests: Int
    let cpuP50: Double
    let cpuP99: Double
}

nonisolated struct WorkerAnalyticsSnapshot: Codable, Sendable {
    let dataPoints: [AggregatedWorkerDataPoint]
    let totalRequests: Int
    let totalErrors: Int
    let totalSubrequests: Int
    let avgCpuP50: Double
    let maxCpuP99: Double
    let loadedDays: Int
}

@MainActor
final class WorkerAnalyticsViewModel: BaseLoadableViewModel {
    let accountId: String
    let scriptName: String
    private let analyticsService: AnalyticsServiceProtocol
    
    @Published var selectedDays: Int = 1
    @Published var loadedDays: Int = 1
    @Published var dataPoints: [AggregatedWorkerDataPoint] = []
    @Published var totalRequests: Int = 0
    @Published var totalErrors: Int = 0
    @Published var totalSubrequests: Int = 0
    @Published var avgCpuP50: Double = 0
    @Published var maxCpuP99: Double = 0
    
    var errorRatePercentage: Double {
        guard totalRequests > 0 else { return 0.0 }
        return (Double(totalErrors) / Double(totalRequests)) * 100.0
    }
    
    init(
        accountId: String,
        scriptName: String,
        analyticsService: AnalyticsServiceProtocol = AnalyticsService.shared
    ) {
        self.accountId = accountId
        self.scriptName = scriptName
        self.analyticsService = analyticsService
        super.init()
    }
    
    private var cacheKey: String {
        "worker_analytics_\(accountId)_\(scriptName)_\(selectedDays)"
    }
    
    public func fetchAnalytics(isRefresh: Bool = false) async {
        let scopedKey = SWRCacheStore.accountScopedKey(cacheKey)
        
        if !hasFetchedData, let cached = await SWRCacheStore.shared.get(forKey: scopedKey, as: WorkerAnalyticsSnapshot.self) {
            await MainActor.run {
                self.dataPoints = cached.dataPoints
                self.totalRequests = cached.totalRequests
                self.totalErrors = cached.totalErrors
                self.totalSubrequests = cached.totalSubrequests
                self.avgCpuP50 = cached.avgCpuP50
                self.maxCpuP99 = cached.maxCpuP99
                self.loadedDays = cached.loadedDays
                self.hasFetchedData = true
            }
        }
        
        await executeLoadingTask(clearError: true) {
            let items = try await self.analyticsService.getWorkerAnalytics(
                accountId: self.accountId,
                scriptName: self.scriptName,
                days: self.selectedDays
            )
            self.processAnalytics(items)
            self.loadedDays = self.selectedDays
            
            let snapshot = WorkerAnalyticsSnapshot(
                dataPoints: self.dataPoints,
                totalRequests: self.totalRequests,
                totalErrors: self.totalErrors,
                totalSubrequests: self.totalSubrequests,
                avgCpuP50: self.avgCpuP50,
                maxCpuP99: self.maxCpuP99,
                loadedDays: self.selectedDays
            )
            await SWRCacheStore.shared.set(snapshot, forKey: scopedKey)
        }
    }
    
    private func processAnalytics(_ items: [WorkerAnalyticsItem]) {
        var pointsMap: [String: (requests: Int, errors: Int, subrequests: Int, cpu50: [Double], cpu99: [Double])] = [:]
        
        var totReq = 0
        var totErr = 0
        var totSub = 0
        var allCpu50: [Double] = []
        var allCpu99: [Double] = []
        
        for item in items {
            guard let dt = item.dimensions.datetimeHour ?? item.dimensions.datetime ?? item.dimensions.date else { continue }
            let req = item.sum?.requests ?? 0
            let err = item.sum?.errors ?? 0
            let sub = item.sum?.subrequests ?? 0
            
            // Cloudflare GraphQL quantiles: cpuTime is in microseconds (µs) if > 50, otherwise ms
            var rawP50 = item.quantiles?.cpuTimeP50 ?? 0
            var rawP99 = item.quantiles?.cpuTimeP99 ?? 0
            if rawP50 > 50 { rawP50 /= 1000.0 }
            if rawP99 > 50 { rawP99 /= 1000.0 }
            
            totReq += req
            totErr += err
            totSub += sub
            if rawP50 > 0 { allCpu50.append(rawP50) }
            if rawP99 > 0 { allCpu99.append(rawP99) }
            
            if var existing = pointsMap[dt] {
                existing.requests += req
                existing.errors += err
                existing.subrequests += sub
                if rawP50 > 0 { existing.cpu50.append(rawP50) }
                if rawP99 > 0 { existing.cpu99.append(rawP99) }
                pointsMap[dt] = existing
            } else {
                pointsMap[dt] = (req, err, sub, rawP50 > 0 ? [rawP50] : [], rawP99 > 0 ? [rawP99] : [])
            }
        }
        
        self.totalRequests = totReq
        self.totalErrors = totErr
        self.totalSubrequests = totSub
        self.avgCpuP50 = allCpu50.isEmpty ? 0 : (allCpu50.reduce(0, +) / Double(allCpu50.count))
        self.maxCpuP99 = allCpu99.max() ?? 0
        
        let sortedKeys = pointsMap.keys.sorted()
        var points: [AggregatedWorkerDataPoint] = []
        for key in sortedKeys {
            if let entry = pointsMap[key] {
                let parsedDate = DateFormatters.parseChartDate(key)
                let avg50 = entry.cpu50.isEmpty ? 0 : (entry.cpu50.reduce(0, +) / Double(entry.cpu50.count))
                let avg99 = entry.cpu99.isEmpty ? 0 : (entry.cpu99.reduce(0, +) / Double(entry.cpu99.count))
                points.append(AggregatedWorkerDataPoint(
                    timestamp: key,
                    date: parsedDate,
                    requests: entry.requests,
                    errors: entry.errors,
                    subrequests: entry.subrequests,
                    cpuP50: avg50,
                    cpuP99: avg99
                ))
            }
        }
        
        self.dataPoints = points
    }
}
