import SwiftUI
import Charts
import MapKit

// MARK: - AnalyticsView

struct AnalyticsView: View {
    // MARK: - Properties
    let zoneId: String
    let zoneName: String
    
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var timeRange: Int = 1
    
    // Interactive Scrubbing States
    @State private var selectedPoint: AnalyticsDataPoint?
    @State private var selectedBandwidthPoint: AnalyticsDataPoint?
    
    // MARK: - Lifecycle / Init
    init(zoneId: String, zoneName: String) {
        self.zoneId = zoneId
        self.zoneName = zoneName
    }
    
    // MARK: - Computed Properties
    private var isHourlyData: Bool {
        if let first = viewModel.dataPoints.first?.dimensions {
            if let dt = first.datetime, dt.contains("T") {
                return true
            }
            if first.date != nil {
                return false
            }
        }
        return viewModel.loadedDays == 1
    }
    
    private var chartXRange: ClosedRange<Date> {
        if let first = viewModel.dataPoints.first,
           let last = viewModel.dataPoints.last {
            let start = dateFromString(first.dimensions.datetime ?? first.dimensions.date ?? "")
            let end = dateFromString(last.dimensions.datetime ?? last.dimensions.date ?? "")
            if start < end {
                return start...end
            } else if start == end {
                return start.addingTimeInterval(-1800)...end.addingTimeInterval(1800)
            }
        }
        let now = Date()
        return now...now.addingTimeInterval(3600)
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.horizontal, CloudnsSpacing.md)
                .padding(.top, CloudnsSpacing.mdSmall)
                .padding(.bottom, CloudnsSpacing.mdSmall)
                .centerConstrainedWidth(maxWidth: 840)
            
            contentBody
        }
        .background(CloudnsColor.groupedBackground)
        .navigationTitle("Zone Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(NotificationCenter.default.publisher(for: .localCachePurged)) { _ in
            viewModel.resetState()
            Task { await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange, isRefresh: true) }
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange)
            }
        }
    }
    
    // MARK: - Private Views
    private var headerBar: some View {
        HStack(alignment: .center, spacing: CloudnsSpacing.smMd) {
            Image(systemName: "globe")
                .foregroundStyle(.blue)
                .font(.title3)
            
            Text(zoneName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Spacer(minLength: CloudnsSpacing.xs)
            
            Picker("Range", selection: $timeRange) {
                Text("24h").tag(1)
                Text("7d").tag(7)
                Text("30d").tag(30)
            }
            .pickerStyle(.segmented)
            .frame(width: 155)
            .onChange(of: timeRange) { newValue in
                HapticManager.impact(.light)
                selectedPoint = nil
                selectedBandwidthPoint = nil
                Task {
                    await viewModel.fetchAnalytics(zoneTag: zoneId, days: newValue)
                }
            }
        }
        .padding(CloudnsSpacing.mdMedium)
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
            VStack(spacing: CloudnsSpacing.md) {
                AnalyticsMetricsGridView(
                    totalRequests: 0,
                    totalCachedRequests: 0,
                    totalBandwidthBytes: 0,
                    totalCachedBandwidthBytes: 0,
                    cachedRatio: 0,
                    formatBytes: viewModel.formatBytes
                )
                .skeletonLoading(true)
            }
            .padding(.horizontal, CloudnsSpacing.md)
            .padding(.bottom, CloudnsSpacing.xl)
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
                                Task { await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange) }
                            }
                        )
                    )
                } else {
                    CloudnsStateOverlayView(
                        state: .empty(
                            icon: "chart.xyaxis.line",
                            title: "No Traffic Data",
                            message: "No HTTP requests recorded for \(zoneName) in the selected time range."
                        )
                    )
                }
                Spacer(minLength: 80)
            }
            .frame(minHeight: 450)
            .padding(.horizontal, CloudnsSpacing.md)
            .centerConstrainedWidth(maxWidth: 840)
        }
        .refreshable {
            await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange, isRefresh: true)
        }
    }
    
    private var analyticsScrollView: some View {
        ScrollView {
            VStack(spacing: CloudnsSpacing.md) {
                AnalyticsMetricsGridView(
                    totalRequests: viewModel.totalRequests,
                    totalCachedRequests: viewModel.totalCachedRequests,
                    totalBandwidthBytes: viewModel.totalBandwidthBytes,
                    totalCachedBandwidthBytes: viewModel.totalCachedBandwidthBytes,
                    cachedRatio: viewModel.cachedRatio,
                    formatBytes: viewModel.formatBytes
                )
                
                AnalyticsRequestsChartView(
                    dataPoints: viewModel.dataPoints,
                    totalRequests: viewModel.totalRequests,
                    chartXRange: chartXRange,
                    isHourlyData: isHourlyData,
                    selectedPoint: $selectedPoint
                )
                
                AnalyticsBandwidthChartView(
                    dataPoints: viewModel.dataPoints,
                    totalBandwidthBytes: viewModel.totalBandwidthBytes,
                    formatBytes: viewModel.formatBytes,
                    chartXRange: chartXRange,
                    isHourlyData: isHourlyData,
                    selectedBandwidthPoint: $selectedBandwidthPoint
                )
                
                if !viewModel.mapDataPoints.isEmpty {
                    AnalyticsCountryDistributionView(mapDataPoints: viewModel.mapDataPoints)
                }
                
                AnalyticsInsightsCardView(
                    totalCachedBandwidthBytes: viewModel.totalCachedBandwidthBytes,
                    cachedRatio: viewModel.cachedRatio,
                    formatBytes: viewModel.formatBytes
                )
            }
            .padding(.horizontal, CloudnsSpacing.md)
            .padding(.bottom, CloudnsSpacing.xl)
            .centerConstrainedWidth(maxWidth: 840)
            .opacity(viewModel.isLoading ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
        }
        .refreshable {
            await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange, isRefresh: true)
        }
    }
    
    // MARK: - Helpers
    private func dateFromString(_ str: String) -> Date {
        DateFormatters.parseChartDate(str)
    }
}
