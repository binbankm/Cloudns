import SwiftUI
import Charts

public struct PagesAnalyticsView: View {
    public let accountId: String
    public let projectName: String
    
    @StateObject private var viewModel: PagesAnalyticsViewModel
    
    public init(accountId: String, projectName: String) {
        self.accountId = accountId
        self.projectName = projectName
        _viewModel = StateObject(wrappedValue: PagesAnalyticsViewModel(accountId: accountId, projectName: projectName))
    }
    
    public var body: some View {
        Group {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                ProgressView()
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if viewModel.hasFetchedData && viewModel.dataPoints.isEmpty && viewModel.deployments.isEmpty {
                if let errorMessage = viewModel.errorMessage {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchAnalytics() }
                            }
                        )
                    )
                } else {
                    StateOverlayView(
                        state: .empty(
                            icon: "chart.xyaxis.line",
                            title: "No Pages Data",
                            message: "No Functions invocations or deployments recorded for \(projectName) in the selected time range."
                        )
                    )
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // 1. Unified Header & Time Range Picker Bar
                        headerBar
                        
                        // 2. 4 Key Metrics Cards Grid
                        metricsGrid
                        
                        // 3. Pages Functions Invocations 折线图 (Line & Area Chart)
                        if !viewModel.dataPoints.isEmpty {
                            functionsLineChartCard
                            cpuLatencyLineChartCard
                        }
                        
                        // 4. Deployments Pipeline Distribution (生产 vs 预览 分布)
                        deploymentsBreakdownCard
                        
                        // 5. Pages Architecture & Deployment Insights Card
                        insightsCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                    .centerConstrainedWidth(maxWidth: 840)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Pages Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchAnalytics()
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchAnalytics()
            }
        }
    }
    
    // MARK: - 1. Header Bar
    private var headerBar: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "square.stack.3d.up.fill")
                .foregroundStyle(.purple)
                .font(.title3)
            
            Text(projectName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Spacer(minLength: 6)
            
            Picker("Range", selection: $viewModel.selectedDays) {
                Text("24H").tag(1)
                Text("7D").tag(7)
                Text("30D").tag(30)
            }
            .pickerStyle(.segmented)
            .frame(width: 145)
            .onChange(of: viewModel.selectedDays) { _ in
                HapticManager.impact(.light)
                Task {
                    await viewModel.fetchAnalytics()
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - 2. Key Metrics Grid
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard(
                title: "Functions Invocations",
                value: formatNumber(viewModel.totalRequests),
                icon: "bolt.horizontal.fill",
                color: .blue,
                badge: "\(viewModel.totalSubrequests) Subrequests"
            )
            
            metricCard(
                title: "Functions Errors",
                value: formatNumber(viewModel.totalErrors),
                icon: "exclamationmark.triangle.fill",
                color: viewModel.totalErrors > 0 ? .red : .green,
                badge: String(format: "%.1f%% Error Rate", viewModel.errorRatePercentage)
            )
            
            metricCard(
                title: "Build Success Rate",
                value: String(format: "%.1f%%", viewModel.deploymentSuccessRate),
                icon: "checkmark.circle.fill",
                color: .green,
                badge: "\(viewModel.deployments.count) Deployments"
            )
            
            metricCard(
                title: "CPU Time (Median)",
                value: String(format: "%.1f ms", viewModel.avgCpuP50),
                icon: "timer",
                color: .cyan,
                badge: String(format: "P99: %.1f ms", viewModel.maxCpuP99)
            )
        }
    }
    
    private func metricCard(title: String, value: String, icon: String, color: Color, badge: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
            }
            
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            
            Text(badge)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - 3. Functions Invocations 折线图 (Line Chart)
    private var functionsLineChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                Text("Functions Invocations")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("Invocations over Time")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Chart {
                ForEach(viewModel.dataPoints) { pt in
                    AreaMark(
                        x: .value("Time", pt.date),
                        y: .value("Requests", pt.requests)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.35), Color.blue.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Time", pt.date),
                        y: .value("Requests", pt.requests)
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                    
                    if pt.errors > 0 {
                        BarMark(
                            x: .value("Time", pt.date),
                            y: .value("Errors", pt.errors)
                        )
                        .foregroundStyle(Color.red.opacity(0.85))
                        .cornerRadius(3)
                    }
                }
            }
            .frame(height: 230)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    if viewModel.selectedDays == 1 {
                        AxisValueLabel(format: .dateTime.hour(), centered: true)
                    } else {
                        AxisValueLabel(format: .dateTime.month().day(), centered: true)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    if let count = value.as(Int.self) {
                        AxisValueLabel {
                            Text(formatNumber(count))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - 4. CPU Execution Latency 双折线图 (Line Chart)
    private var cpuLatencyLineChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.subheadline)
                    .foregroundStyle(.cyan)
                Text("CPU Time")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                HStack(spacing: 8) {
                    Label("P50 (Median)", systemImage: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                    Label("P99", systemImage: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            
            Chart {
                ForEach(viewModel.dataPoints) { pt in
                    LineMark(
                        x: .value("Time", pt.date),
                        y: .value("CPU P50", pt.cpuP50)
                    )
                    .foregroundStyle(Color.cyan)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Time", pt.date),
                        y: .value("CPU P99", pt.cpuP99)
                    )
                    .foregroundStyle(Color.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 220)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    if viewModel.selectedDays == 1 {
                        AxisValueLabel(format: .dateTime.hour(), centered: true)
                    } else {
                        AxisValueLabel(format: .dateTime.month().day(), centered: true)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    if let ms = value.as(Double.self) {
                        AxisValueLabel {
                            Text(String(format: "%.1f ms", ms))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - 5. Deployments Pipeline Card
    private var deploymentsBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.subheadline)
                    .foregroundStyle(.purple)
                Text("Deployments Pipeline")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("Branch Breakdown")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 16) {
                // Production Bar
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Circle().fill(Color.purple).frame(width: 8, height: 8)
                        Text("Production")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(viewModel.productionDeploymentsCount)")
                            .font(.headline.monospacedDigit())
                    }
                    ProgressView(value: Double(viewModel.productionDeploymentsCount), total: max(1, Double(viewModel.deployments.count)))
                        .tint(.purple)
                }
                .padding(12)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Preview Bar
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Circle().fill(Color.blue).frame(width: 8, height: 8)
                        Text("Preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(viewModel.previewDeploymentsCount)")
                            .font(.headline.monospacedDigit())
                    }
                    ProgressView(value: Double(viewModel.previewDeploymentsCount), total: max(1, Double(viewModel.deployments.count)))
                        .tint(.blue)
                }
                .padding(12)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - 6. Insights & Summary
    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Pages Edge & Pipeline Summary", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.purple)
            
            HStack {
                Text("Subrequest Ratio")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                let ratio = viewModel.totalRequests > 0 ? Double(viewModel.totalSubrequests) / Double(viewModel.totalRequests) : 0
                Text(String(format: "%.1f subrequests / req", ratio))
                    .font(.caption.weight(.semibold).monospacedDigit())
            }
            
            Divider()
            
            HStack {
                Text("Edge Functions Status")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.totalErrors == 0 ? "100% Operational" : "\(viewModel.totalErrors) Invocations Failed")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(viewModel.totalErrors == 0 ? .green : .orange)
            }
            
            Divider()
            
            HStack {
                Text("Deployment Pipeline")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.1f%% Success Rate", viewModel.deploymentSuccessRate))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatNumber(_ num: Int) -> String {
        if num < 1000 { return "\(num)" }
        let k = Double(num) / 1000.0
        if k < 1000 { return String(format: "%.1fK", k) }
        let m = k / 1000.0
        return String(format: "%.2fM", m)
    }
}
