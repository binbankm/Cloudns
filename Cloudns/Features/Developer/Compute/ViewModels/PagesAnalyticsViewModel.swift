import Foundation
import SwiftUI
import Combine

nonisolated struct PagesDeploymentStat: Identifiable, Equatable, Sendable {
    var id: String { deploymentId }
    let deploymentId: String
    let environment: String
    let status: String
    let date: Date
    let isSuccess: Bool
}

nonisolated struct PagesAnalyticsSnapshot: Codable, Sendable {
    let dataPoints: [AggregatedWorkerDataPoint]
    let totalRequests: Int
    let totalErrors: Int
    let totalSubrequests: Int
    let avgCpuP50: Double
    let maxCpuP99: Double
    let deployments: [PagesDeployment]
    let productionDeploymentsCount: Int
    let previewDeploymentsCount: Int
    let deploymentSuccessRate: Double
    let customDomainsCount: Int
    let loadedDays: Int
}

@MainActor
final class PagesAnalyticsViewModel: BaseLoadableViewModel {
    // MARK: - Private Properties
    let accountId: String
    let projectName: String
    private let analyticsService: AnalyticsServiceProtocol
    private let pagesService: PagesServiceProtocol
    
    // MARK: - Published Properties
    @Published var selectedDays: Int = 1
    @Published var loadedDays: Int = 1
    @Published var dataPoints: [AggregatedWorkerDataPoint] = []
    @Published var totalRequests: Int = 0
    @Published var totalErrors: Int = 0
    @Published var totalSubrequests: Int = 0
    @Published var avgCpuP50: Double = 0
    @Published var maxCpuP99: Double = 0
    
    // Deployment Specific Analytics
    @Published var deployments: [PagesDeployment] = []
    @Published var productionDeploymentsCount: Int = 0
    @Published var previewDeploymentsCount: Int = 0
    @Published var deploymentSuccessRate: Double = 100.0
    @Published var customDomainsCount: Int = 0
    
    var errorRatePercentage: Double {
        guard totalRequests > 0 else { return 0.0 }
        return (Double(totalErrors) / Double(totalRequests)) * 100.0
    }
    
    // MARK: - Lifecycle / Init
    init(
        accountId: String,
        projectName: String,
        analyticsService: AnalyticsServiceProtocol = AnalyticsService.shared,
        pagesService: PagesServiceProtocol = PagesService.shared
    ) {
        self.accountId = accountId
        self.projectName = projectName
        self.analyticsService = analyticsService
        self.pagesService = pagesService
        super.init()
    }
    
    private var cacheKey: String {
        "pages_analytics_\(accountId)_\(projectName)_\(selectedDays)"
    }
    
    // MARK: - Public Methods
    public func fetchAnalytics(isRefresh: Bool = false) async {
        let scopedKey = SWRCacheStore.accountScopedKey(cacheKey)
        
        // 1. [Stale] 0ms 尝试从缓存恢复历史数据
        if !hasFetchedData, let cached = await SWRCacheStore.shared.get(forKey: scopedKey, as: PagesAnalyticsSnapshot.self) {
            await MainActor.run {
                self.dataPoints = cached.dataPoints
                self.totalRequests = cached.totalRequests
                self.totalErrors = cached.totalErrors
                self.totalSubrequests = cached.totalSubrequests
                self.avgCpuP50 = cached.avgCpuP50
                self.maxCpuP99 = cached.maxCpuP99
                self.deployments = cached.deployments
                self.productionDeploymentsCount = cached.productionDeploymentsCount
                self.previewDeploymentsCount = cached.previewDeploymentsCount
                self.deploymentSuccessRate = cached.deploymentSuccessRate
                self.customDomainsCount = cached.customDomainsCount
                self.loadedDays = cached.loadedDays
                self.hasFetchedData = true
            }
        }
        
        // 2. [Revalidate] 并发获取 Functions 性能指标、部署记录与自定义域名
        await executeLoadingTask(clearError: true) {
            async let fetchFunctions: Void = self.fetchFunctionsMetrics()
            async let fetchDeployments: Void = self.fetchDeploymentsInfo()
            async let fetchDomains: Void = self.fetchDomainsInfo()
            
            _ = await (fetchFunctions, fetchDeployments, fetchDomains)
            self.loadedDays = self.selectedDays
            
            // 成功后持久化最新快照
            let snapshot = PagesAnalyticsSnapshot(
                dataPoints: self.dataPoints,
                totalRequests: self.totalRequests,
                totalErrors: self.totalErrors,
                totalSubrequests: self.totalSubrequests,
                avgCpuP50: self.avgCpuP50,
                maxCpuP99: self.maxCpuP99,
                deployments: self.deployments,
                productionDeploymentsCount: self.productionDeploymentsCount,
                previewDeploymentsCount: self.previewDeploymentsCount,
                deploymentSuccessRate: self.deploymentSuccessRate,
                customDomainsCount: self.customDomainsCount,
                loadedDays: self.selectedDays
            )
            await SWRCacheStore.shared.set(snapshot, forKey: scopedKey)
        }
    }
    
    // MARK: - Private Methods
    private func fetchFunctionsMetrics() async {
        do {
            let items = try await self.analyticsService.getPagesAnalytics(
                accountId: self.accountId,
                projectName: self.projectName,
                days: self.selectedDays
            )
            self.processAnalytics(items)
        } catch {
            // 保留已有数据，不作破坏性清空
        }
    }
    
    private func fetchDeploymentsInfo() async {
        do {
            let deps = try await self.pagesService.getPagesDeployments(accountId: self.accountId, projectName: self.projectName)
            self.deployments = deps
            
            var prodCount = 0
            var prevCount = 0
            var successCount = 0
            
            for dep in deps {
                let env = dep.environment?.lowercased() ?? "production"
                if env == "production" {
                    prodCount += 1
                } else {
                    prevCount += 1
                }
                
                let status = dep.latestStage?.status?.lowercased() ?? "success"
                if status == "success" || status == "active" {
                    successCount += 1
                }
            }
            
            self.productionDeploymentsCount = prodCount
            self.previewDeploymentsCount = prevCount
            self.deploymentSuccessRate = deps.isEmpty ? 100.0 : (Double(successCount) / Double(deps.count)) * 100.0
        } catch {
            // 保留已有部署数据
        }
    }
    
    private func fetchDomainsInfo() async {
        do {
            let doms = try await self.pagesService.getPagesDomains(accountId: self.accountId, projectName: self.projectName)
            self.customDomainsCount = doms.count
        } catch {
            // 保留已有域名数量
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
