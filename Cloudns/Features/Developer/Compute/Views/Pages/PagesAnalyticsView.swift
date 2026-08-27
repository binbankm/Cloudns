import SwiftUI
import Charts

// MARK: - PagesAnalyticsView

public struct PagesAnalyticsView: View {
    // MARK: - Properties
    public let accountId: String
    public let projectName: String
    
    @StateObject private var viewModel: PagesAnalyticsViewModel
    
    // Interactive Scrubbing States
    @State private var selectedPoint: AggregatedWorkerDataPoint?
    @State private var selectedCpuPoint: AggregatedWorkerDataPoint?
    
    // MARK: - Lifecycle / Init
    public init(accountId: String, projectName: String) {
        self.accountId = accountId
        self.projectName = projectName
        _viewModel = StateObject(
            wrappedValue: PagesAnalyticsViewModel(accountId: accountId, projectName: projectName)
        )
    }
    
    // MARK: - Computed Properties
    private var isHourlyData: Bool {
        if let first = viewModel.dataPoints.first {
            return first.timestamp.contains("T") || first.timestamp.contains(":")
        }
        return viewModel.loadedDays == 1
    }
    
    private var chartXRange: ClosedRange<Date> {
        if let first = viewModel.dataPoints.first?.date,
           let last = viewModel.dataPoints.last?.date {
            if first < last {
                return first...last
            } else if first == last {
                return first.addingTimeInterval(-1800)...last.addingTimeInterval(1800)
            }
        }
        let now = Date()
        return now...now.addingTimeInterval(3600)
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .centerConstrainedWidth(maxWidth: 840)
            
            contentBody
        }
        .background(CloudnsColor.groupedBackground)
        .navigationTitle("Pages Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchAnalytics()
            }
        }
    }
    
    // MARK: - Private Views
    private var headerBar: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "globe.americas.fill")
                .foregroundStyle(.blue)
                .font(.title3)
            
            Text(projectName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Spacer(minLength: 4)
            
            Picker("Range", selection: $viewModel.selectedDays) {
                Text("24h").tag(1)
                Text("7d").tag(7)
                Text("30d").tag(30)
            }
            .pickerStyle(.segmented)
            .frame(width: 155)
            .onChange(of: viewModel.selectedDays) { _ in
                HapticManager.impact(.light)
                selectedPoint = nil
                selectedCpuPoint = nil
                Task {
                    await viewModel.fetchAnalytics()
                }
            }
        }
        .padding(14)
        .background(CloudnsColor.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.lg))
    }
    
    @ViewBuilder
    private var contentBody: some View {
        if !viewModel.hasFetchedData && viewModel.isLoading {
            skeletonLoadingView
        } else if viewModel.hasFetchedData && viewModel.dataPoints.isEmpty {
            emptyStateView
        } else {
            analyticsScrollView
        }
    }
    
    private var skeletonLoadingView: some View {
        ScrollView {
            VStack(spacing: 16) {
                PagesAnalyticsMetricsGridView(
                    totalRequests: 0,
                    totalSubrequests: 0,
                    totalErrors: 0,
                    errorRatePercentage: 0,
                    deploymentSuccessRate: 0,
                    totalDeploymentsCount: 0,
                    customDomainsCount: 0
                )
                .skeletonLoading(true)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
            .centerConstrainedWidth(maxWidth: 840)
        }
    }
    
    private var emptyStateView: some View {
        ScrollView {
            VStack {
                Spacer(minLength: 40)
                if let errorMessage = viewModel.errorMessage {
                    CloudnsStateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchAnalytics(isRefresh: true) }
                            }
                        )
                    )
                } else {
                    CloudnsStateOverlayView(
                        state: .empty(
                            icon: "chart.xyaxis.line",
                            title: "No Invocations Data",
                            message: "No Pages Functions invocations recorded for \(projectName) in the selected range."
                        )
                    )
                }
                Spacer(minLength: 80)
            }
            .frame(minHeight: 450)
            .padding(.horizontal, 16)
            .centerConstrainedWidth(maxWidth: 840)
        }
        .refreshable {
            await viewModel.fetchAnalytics(isRefresh: true)
        }
    }
    
    private var analyticsScrollView: some View {
        ScrollView {
            VStack(spacing: 16) {
                PagesAnalyticsMetricsGridView(
                    totalRequests: viewModel.totalRequests,
                    totalSubrequests: viewModel.totalSubrequests,
                    totalErrors: viewModel.totalErrors,
                    errorRatePercentage: viewModel.errorRatePercentage,
                    deploymentSuccessRate: viewModel.deploymentSuccessRate,
                    totalDeploymentsCount: viewModel.deployments.count,
                    customDomainsCount: viewModel.customDomainsCount
                )
                
                PagesInvocationsChartView(
                    dataPoints: viewModel.dataPoints,
                    totalRequests: viewModel.totalRequests,
                    loadedDays: viewModel.loadedDays,
                    chartXRange: chartXRange,
                    isHourlyData: isHourlyData,
                    selectedPoint: $selectedPoint
                )
                
                WorkerCPULatencyChartView(
                    dataPoints: viewModel.dataPoints,
                    avgCpuP50: viewModel.avgCpuP50,
                    maxCpuP99: viewModel.maxCpuP99,
                    loadedDays: viewModel.loadedDays,
                    chartXRange: chartXRange,
                    isHourlyData: isHourlyData,
                    selectedCpuPoint: $selectedCpuPoint
                )
                
                PagesDeploymentsPipelineCardView(
                    productionDeploymentsCount: viewModel.productionDeploymentsCount,
                    previewDeploymentsCount: viewModel.previewDeploymentsCount,
                    totalDeploymentsCount: viewModel.deployments.count
                )
                
                PagesAnalyticsInsightsView(
                    totalRequests: viewModel.totalRequests,
                    totalSubrequests: viewModel.totalSubrequests,
                    totalErrors: viewModel.totalErrors,
                    deploymentSuccessRate: viewModel.deploymentSuccessRate
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
            .centerConstrainedWidth(maxWidth: 840)
            .opacity(viewModel.isLoading ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
        }
        .refreshable {
            await viewModel.fetchAnalytics(isRefresh: true)
        }
    }
}
