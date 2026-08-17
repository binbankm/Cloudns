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
        ScrollView {
            VStack(spacing: 20) {
                // 1. Unified Header & Time Range Picker Bar
                headerBar
                
                // 2. 4 Key Metrics Cards Grid
                metricsGrid
                
                // 3. Pages Functions Invocations 折线图 (Line & Area Chart)
                functionsLineChartCard
                
                // 4. V8 Isolate Execution Latency 双折线图 (Line Chart P50 & P99)
                cpuLatencyLineChartCard
                
                // 5. Deployments Pipeline Distribution (生产 vs 预览 分布)
                deploymentsBreakdownCard
                
                // 6. Pages Architecture & Deployment Insights Card
                insightsCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .centerConstrainedWidth(maxWidth: 840)
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
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.richtext.fill")
                        .foregroundStyle(.purple)
                        .font(.headline)
                    Text(projectName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                HStack(spacing: 6) {
                    Text("Pages Edge Full-Stack")
                        .font(.caption2.monospaced())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.12))
                        .foregroundStyle(.purple)
                        .clipShape(Capsule())
                    
                    if viewModel.customDomainsCount > 0 {
                        Text("\(viewModel.customDomainsCount) Custom Domains")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Picker("Range", selection: $viewModel.selectedDays) {
                Text("24H").tag(1)
                Text("7D").tag(7)
                Text("30D").tag(30)
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
            .onChange(of: viewModel.selectedDays) { _ in
                Task { await viewModel.fetchAnalytics() }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    // MARK: - 2. Key Metrics Grid
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard(
                title: "Edge Invocations",
                value: formatNumber(viewModel.totalRequests),
                icon: "bolt.horizontal.fill",
                color: .blue,
                badge: "\(viewModel.totalSubrequests) subreqs"
            )
            
            metricCard(
                title: "Functions Errors",
                value: "\(viewModel.totalErrors)",
                icon: "exclamationmark.triangle.fill",
                color: viewModel.totalErrors > 0 ? .orange : .green,
                badge: String(format: "%.2f%% err", viewModel.errorRatePercentage)
            )
            
            metricCard(
                title: "Total Deployments",
                value: "\(viewModel.deployments.count)",
                icon: "arrow.triangle.2.circlepath.circle.fill",
                color: .purple,
                badge: "\(viewModel.productionDeploymentsCount) Prod / \(viewModel.previewDeploymentsCount) Prev"
            )
            
            metricCard(
                title: "Build Success Rate",
                value: String(format: "%.1f%%", viewModel.deploymentSuccessRate),
                icon: "checkmark.seal.fill",
                color: .green,
                badge: String(format: "Median CPU: %.1fms", viewModel.avgCpuP50)
            )
        }
    }
    
    private func metricCard(title: String, value: String, icon: String, color: Color, badge: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
            
            Text(badge)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.12))
                .foregroundStyle(color)
                .clipShape(Capsule())
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    // MARK: - 3. Functions Invocations 折线图 (Line Chart)
    private var functionsLineChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                Text("Pages Functions Invocations (函数调用折线图)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("Invocations/Time")
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
                    .interpolationMethod(.monotone)
                    
                    LineMark(
                        x: .value("Time", pt.date),
                        y: .value("Requests", pt.requests)
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .symbol(Circle().strokeBorder(lineWidth: 1.5))
                    .symbolSize(32)
                    .interpolationMethod(.monotone)
                    
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
                    AxisValueLabel(format: .dateTime.hour().minute(), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    AxisValueLabel()
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
                Text("V8 Isolate CPU Latency (执行耗时折线图 ms)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                HStack(spacing: 8) {
                    Label("P50 (中位数)", systemImage: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                    Label("P99 (极端值)", systemImage: "circle.fill")
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
                    .symbol(Circle().strokeBorder(lineWidth: 1.5))
                    .symbolSize(32)
                    .interpolationMethod(.monotone)
                    
                    LineMark(
                        x: .value("Time", pt.date),
                        y: .value("CPU P99", pt.cpuP99)
                    )
                    .foregroundStyle(Color.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [3]))
                    .symbol(Circle().strokeBorder(lineWidth: 1.5))
                    .symbolSize(28)
                    .interpolationMethod(.monotone)
                }
            }
            .frame(height: 220)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    AxisValueLabel(format: .dateTime.hour().minute(), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    AxisValueLabel()
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
                Text("Deployments Pipeline (部署环境分布)")
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
                        Text("Production Branch")
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
                        Text("Preview PRs")
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
            Label("Pages Performance & Health Summary", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.purple)
            
            HStack {
                Text("Subrequest Amplification")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                let ratio = viewModel.totalRequests > 0 ? Double(viewModel.totalSubrequests) / Double(viewModel.totalRequests) : 0
                Text(String(format: "%.1fx (D1/KV/Fetch)", ratio))
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
                Text(String(format: "%.1f%% Build Success Rate", viewModel.deploymentSuccessRate))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private func formatNumber(_ num: Int) -> String {
        if num < 1000 { return "\(num)" }
        let k = Double(num) / 1000.0
        if k < 1000 { return String(format: "%.1fK", k) }
        let m = k / 1000.0
        return String(format: "%.2fM", m)
    }
}
