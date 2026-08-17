import Foundation
import SwiftUI
import Combine

public struct PagesDeploymentStat: Identifiable, Equatable {
    public var id: String { deploymentId }
    public let deploymentId: String
    public let environment: String
    public let status: String
    public let date: Date
    public let isSuccess: Bool
}

@MainActor
public final class PagesAnalyticsViewModel: BaseLoadableViewModel {
    public let accountId: String
    public let projectName: String
    private let apiClient = CloudflareAPIClient.shared
    private let pagesService = PagesService.shared
    
    @Published public var selectedDays: Int = 1
    @Published public var dataPoints: [AggregatedWorkerDataPoint] = []
    @Published public var totalRequests: Int = 0
    @Published public var totalErrors: Int = 0
    @Published public var totalSubrequests: Int = 0
    @Published public var avgCpuP50: Double = 0
    @Published public var maxCpuP99: Double = 0
    
    // Deployment Specific Analytics
    @Published public var deployments: [PagesDeployment] = []
    @Published public var productionDeploymentsCount: Int = 0
    @Published public var previewDeploymentsCount: Int = 0
    @Published public var deploymentSuccessRate: Double = 100.0
    @Published public var customDomainsCount: Int = 0
    
    public var errorRatePercentage: Double {
        guard totalRequests > 0 else { return 0.0 }
        return (Double(totalErrors) / Double(totalRequests)) * 100.0
    }
    
    public init(accountId: String, projectName: String) {
        self.accountId = accountId
        self.projectName = projectName
        super.init()
    }
    
    public func fetchAnalytics() async {
        await executeLoadingTask {
            // Concurrent fetching for Functions metrics, deployments list, and custom domains
            async let fetchFunctions: Void = self.fetchFunctionsMetrics()
            async let fetchDeployments: Void = self.fetchDeploymentsInfo()
            async let fetchDomains: Void = self.fetchDomainsInfo()
            
            _ = await (fetchFunctions, fetchDeployments, fetchDomains)
        }
    }
    
    private func fetchFunctionsMetrics() async {
        do {
            let items = try await self.apiClient.getPagesAnalytics(
                accountId: self.accountId,
                projectName: self.projectName,
                days: self.selectedDays
            )
            self.processAnalytics(items)
        } catch {
            self.dataPoints = []
            self.totalRequests = 0
            self.totalErrors = 0
            self.totalSubrequests = 0
            self.avgCpuP50 = 0
            self.maxCpuP99 = 0
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
            self.deployments = []
            self.productionDeploymentsCount = 0
            self.previewDeploymentsCount = 0
            self.deploymentSuccessRate = 0.0
        }
    }
    
    private func fetchDomainsInfo() async {
        do {
            let doms = try await self.pagesService.getPagesDomains(accountId: self.accountId, projectName: self.projectName)
            self.customDomainsCount = doms.count
        } catch {
            self.customDomainsCount = 0
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
