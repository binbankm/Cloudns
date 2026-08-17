import SwiftUI
import Charts

public struct WorkerAnalyticsView: View {
    public let accountId: String
    public let scriptName: String
    
    @StateObject private var viewModel: WorkerAnalyticsViewModel
    
    public init(accountId: String, scriptName: String) {
        self.accountId = accountId
        self.scriptName = scriptName
        _viewModel = StateObject(wrappedValue: WorkerAnalyticsViewModel(accountId: accountId, scriptName: scriptName))
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. Unified Header & Time Range Picker Bar
                headerBar
                
                // 2. 4 Key Metrics Cards Grid
                metricsGrid
                
                // 3. Invocations & Errors 折线图 (Line & Area Chart with Error Bars)
                invocationsLineChartCard
                
                // 4. CPU Execution Latency 双折线图 (Line Chart P50 & P99)
                cpuLatencyLineChartCard
                
                // 5. Performance Insights Card
                insightsCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .centerConstrainedWidth(maxWidth: 840)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Worker Analytics")
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
    
    // MARK: - 1. Time Range Picker Bar
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: "curlybraces.square.fill")
                        .foregroundStyle(.purple)
                        .font(.headline)
                    Text(scriptName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                Text("Workers V8 Isolate")
                    .font(.caption2.monospaced())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.12))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
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
    
    // MARK: - 2. 4 Metrics Cards Grid
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard(
                title: "Total Invocations",
                value: formatNumber(viewModel.totalRequests),
                icon: "waveform.path.ecg",
                color: .purple,
                badge: "\(viewModel.totalSubrequests) subreqs"
            )
            
            metricCard(
                title: "Error Count",
                value: "\(viewModel.totalErrors)",
                icon: "exclamationmark.triangle.fill",
                color: viewModel.totalErrors > 0 ? .orange : .green,
                badge: String(format: "%.2f%% err", viewModel.errorRatePercentage)
            )
            
            metricCard(
                title: "Success Rate",
                value: String(format: "%.1f%%", max(0, 100.0 - viewModel.errorRatePercentage)),
                icon: "checkmark.seal.fill",
                color: .green,
                badge: "Edge Normal"
            )
            
            metricCard(
                title: "Median CPU Time",
                value: String(format: "%.2f ms", viewModel.avgCpuP50),
                icon: "bolt.fill",
                color: .cyan,
                badge: String(format: "P99: %.1fms", viewModel.maxCpuP99)
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
    
    // MARK: - 3. Invocations 折线图 (Line Chart)
    private var invocationsLineChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .font(.subheadline)
                    .foregroundStyle(.purple)
                Text("Invocations Volume & Errors (调用量折线图)")
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
                            colors: [Color.purple.opacity(0.35), Color.purple.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)
                    
                    LineMark(
                        x: .value("Time", pt.date),
                        y: .value("Requests", pt.requests)
                    )
                    .foregroundStyle(Color.purple)
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
    
    // MARK: - 4. CPU Latency 双折线图 (Line Chart)
    private var cpuLatencyLineChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.subheadline)
                    .foregroundStyle(.cyan)
                Text("CPU Execution Latency (耗时折线图 ms)")
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
    
    // MARK: - 5. Insights & Summary
    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Performance Summary", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.purple)
            
            HStack {
                Text("Subrequest Amplification")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                let ratio = viewModel.totalRequests > 0 ? Double(viewModel.totalSubrequests) / Double(viewModel.totalRequests) : 0
                Text(String(format: "%.1fx", ratio))
                    .font(.caption.weight(.semibold).monospacedDigit())
            }
            
            Divider()
            
            HStack {
                Text("Status Health")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.totalErrors == 0 ? "100% Healthy" : "\(viewModel.totalErrors) Exceptions Observed")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(viewModel.totalErrors == 0 ? .green : .orange)
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
