import SwiftUI
import Charts

public struct PagesAnalyticsView: View {
    public let accountId: String
    public let projectName: String
    
    @StateObject private var viewModel: PagesAnalyticsViewModel
    
    // Interactive Scrubbing States
    @State private var selectedPoint: AggregatedWorkerDataPoint?
    @State private var selectedCpuPoint: AggregatedWorkerDataPoint?
    
    public init(accountId: String, projectName: String) {
        self.accountId = accountId
        self.projectName = projectName
        _viewModel = StateObject(wrappedValue: PagesAnalyticsViewModel(accountId: accountId, projectName: projectName))
    }
    
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
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. Unified Header & Time Range Picker Bar
            headerBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)
            
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Pages Analytics..."))
            } else if viewModel.hasFetchedData && viewModel.dataPoints.isEmpty && viewModel.deployments.isEmpty {
                ScrollView {
                    VStack {
                        Spacer(minLength: 40)
                        if let errorMessage = viewModel.errorMessage {
                            HIGContentState(
                                .error(
                                    message: LocalizedStringKey(errorMessage),
                                    retryAction: {
                                        Task { await viewModel.fetchAnalytics(isRefresh: true) }
                                    }
                                )
                            )
                        } else {
                            HIGContentState(
                                .empty(
                                    title: "No Pages Data",
                                    systemImage: "chart.xyaxis.line",
                                    description: "No Functions invocations or deployments recorded for \(projectName) in the selected time range."
                                )
                            )
                        }
                        Spacer(minLength: 80)
                    }
                    .frame(minHeight: 450)
                    .padding(.horizontal, 16)
                }
                .refreshable {
                    await viewModel.fetchAnalytics(isRefresh: true)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // 2. 4 Key Metrics Cards Grid (Non-lazy Grid for rock-solid stability)
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
                    .padding(.bottom, 28)
                    .opacity(viewModel.isLoading ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
                }
                .refreshable {
                    await viewModel.fetchAnalytics(isRefresh: true)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Pages Analytics")
        .navigationBarTitleDisplayMode(.inline)
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
                HIGFeedback.impact(.light)
                selectedPoint = nil
                selectedCpuPoint = nil
                Task {
                    await viewModel.fetchAnalytics()
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - 2. Key Metrics Grid
    private var metricsGrid: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                metricCard(
                    title: "Functions Invocations",
                    value: formatNumber(viewModel.totalRequests),
                    icon: "bolt.horizontal.fill",
                    color: .blue,
                    badge: "\(formatNumber(viewModel.totalSubrequests)) Subrequests"
                )
                
                metricCard(
                    title: "Functions Errors",
                    value: formatNumber(viewModel.totalErrors),
                    icon: "exclamationmark.triangle.fill",
                    color: viewModel.totalErrors > 0 ? .red : .green,
                    badge: "\((viewModel.errorRatePercentage / 100.0).formatted(.percent.precision(.fractionLength(1)))) Error Rate"
                )
            }
            
            GridRow {
                metricCard(
                    title: "Deploy Success Rate",
                    value: (viewModel.deploymentSuccessRate / 100.0).formatted(.percent.precision(.fractionLength(0))),
                    icon: "checkmark.seal.fill",
                    color: .green,
                    badge: "\(viewModel.deployments.count) Total Deploys"
                )
                
                metricCard(
                    title: "Active Domains",
                    value: "\(viewModel.customDomainsCount)",
                    icon: "globe",
                    color: .purple,
                    badge: "Custom Domains"
                )
            }
        }
    }
    
    private func metricCard(title: LocalizedStringKey, value: String, icon: String, color: Color, badge: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 22, height: 22)
                    Image(systemName: icon)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(color)
                }
                .accessibilityHidden(true)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Spacer()
            }
            
            Spacer(minLength: 2)
            
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            Spacer(minLength: 2)
            
            Text(badge)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 102, maxHeight: 102, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - 3. Functions Invocations 折线图 (Line Chart with Live Scrubbing)
    private var functionsLineChartCard: some View {
        let maxReq = viewModel.dataPoints.map { $0.requests }.max() ?? 10
        let yUpper = max(10.0, Double(maxReq) * 1.18)
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.blue)
                        Text("Functions Traffic")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(verbatim: formatNumber(selectedPoint?.requests ?? viewModel.totalRequests))
                            .font(.system(.title, design: .rounded).weight(.bold).monospacedDigit())
                            .foregroundStyle(.primary)
                        Text(selectedPoint != nil ? "requests" : "total")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        
                        if let selected = selectedPoint, selected.errors > 0 {
                            Text("(\(selected.errors) errors)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                Spacer()
                
                if let selected = selectedPoint {
                    let dateStr = formattedPointDate(selected)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                        Text(verbatim: dateStr)
                            .font(.caption2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
                } else {
                    Text("Drag to Inspect")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(minHeight: 48)
            
            Chart {
                ForEach(viewModel.dataPoints) { pt in
                    AreaMark(
                        x: .value("Time", pt.date),
                        y: .value("Requests", pt.requests)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.32), Color.blue.opacity(0.01)],
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
                    .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                    
                    if pt.errors > 0 {
                        BarMark(
                            x: .value("Time", pt.date),
                            y: .value("Errors", pt.errors),
                            width: .fixed(6)
                        )
                        .foregroundStyle(Color.red.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    }
                }
                
                if let selected = selectedPoint {
                    RuleMark(x: .value("Time", selected.date))
                        .foregroundStyle(Color.blue.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                    
                    PointMark(
                        x: .value("Time", selected.date),
                        y: .value("Requests", selected.requests)
                    )
                    .symbol {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.25))
                                .frame(width: 16, height: 16)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .shadow(color: Color.blue, radius: 4)
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
            .id("pages_functions_\(viewModel.loadedDays)")
            .frame(height: 220)
            .chartPlotStyle { plot in
                plot.clipped()
            }
            .chartYScale(domain: 0...yUpper)
            .chartXScale(domain: chartXRange)
            .transaction { $0.animation = nil }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    if isHourlyData {
                        AxisValueLabel(format: .dateTime.hour(), collisionResolution: .greedy)
                            .font(.caption2)
                    } else {
                        AxisValueLabel(format: .dateTime.month().day(), collisionResolution: .greedy)
                            .font(.caption2)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    if let count = value.as(Int.self) {
                        AxisValueLabel {
                            Text(verbatim: formatNumber(count))
                                .frame(width: 44, alignment: .trailing)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let origin = geo[proxy.plotAreaFrame].origin
                                    let locationX = value.location.x - origin.x
                                    guard locationX >= 0, locationX <= proxy.plotAreaSize.width else { return }
                                    
                                    if let date: Date = proxy.value(atX: locationX) {
                                        if let closest = findClosestWorkerPoint(for: date, in: viewModel.dataPoints) {
                                            if selectedPoint?.id != closest.id {
                                                HIGFeedback.impact(.light)
                                                selectedPoint = closest
                                            }
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    selectedPoint = nil
                                }
                        )
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - 4. CPU Execution Latency 双折线图 (Line Chart with Live Scrubbing)
    private var cpuLatencyLineChartCard: some View {
        let maxCpu = viewModel.dataPoints.map { max($0.cpuP50, $0.cpuP99) }.max() ?? 10.0
        let yUpper = max(2.0, maxCpu * 1.18)
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.cyan)
                        Text("CPU Execution Time")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    if let selected = selectedCpuPoint {
                        HStack(alignment: .lastTextBaseline, spacing: 8) {
                            Text("\(selected.cpuP50.formatted(.number.precision(.fractionLength(2)))) ms")
                                .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                                .foregroundStyle(.cyan)
                            Text("P50")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            
                            Text("•")
                                .foregroundStyle(.tertiary)
                            
                            Text("\(selected.cpuP99.formatted(.number.precision(.fractionLength(2)))) ms")
                                .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                                .foregroundStyle(.orange)
                            Text("P99")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack(alignment: .lastTextBaseline, spacing: 8) {
                            Text("\(viewModel.avgCpuP50.formatted(.number.precision(.fractionLength(2)))) ms")
                                .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                                .foregroundStyle(.cyan)
                            Text("avg P50")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            
                            Text("•")
                                .foregroundStyle(.tertiary)
                            
                            Text("\(viewModel.maxCpuP99.formatted(.number.precision(.fractionLength(2)))) ms")
                                .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                                .foregroundStyle(.orange)
                            Text("max P99")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                if let selected = selectedCpuPoint {
                    let dateStr = formattedPointDate(selected)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 6, height: 6)
                        Text(verbatim: dateStr)
                            .font(.caption2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.12))
                    .clipShape(Capsule())
                } else {
                    HStack(spacing: 8) {
                        Label("P50", systemImage: "circle.fill")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.cyan)
                        Label("P99", systemImage: "circle.fill")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.orange)
                    }
                }
            }
            .frame(minHeight: 48)
            
            Chart {
                ForEach(viewModel.dataPoints) { pt in
                    LineMark(
                        x: .value("Time", pt.date),
                        y: .value("CPU P50", pt.cpuP50)
                    )
                    .foregroundStyle(Color.cyan)
                    .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                    
                    LineMark(
                        x: .value("Time", pt.date),
                        y: .value("CPU P99", pt.cpuP99)
                    )
                    .foregroundStyle(Color.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [4, 3]))
                    .interpolationMethod(.monotone)
                }
                
                if let selected = selectedCpuPoint {
                    RuleMark(x: .value("Time", selected.date))
                        .foregroundStyle(Color.cyan.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                    
                    PointMark(
                        x: .value("Time", selected.date),
                        y: .value("CPU P50", selected.cpuP50)
                    )
                    .symbol {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(Color.cyan, lineWidth: 2))
                            .shadow(color: Color.cyan, radius: 4)
                    }
                }
            }
            .id("pages_cpu_\(viewModel.loadedDays)")
            .frame(height: 200)
            .chartPlotStyle { plot in
                plot.clipped()
            }
            .chartYScale(domain: 0...yUpper)
            .chartXScale(domain: chartXRange)
            .transaction { $0.animation = nil }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    if isHourlyData {
                        AxisValueLabel(format: .dateTime.hour(), collisionResolution: .greedy)
                            .font(.caption2)
                    } else {
                        AxisValueLabel(format: .dateTime.month().day(), collisionResolution: .greedy)
                            .font(.caption2)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    if let ms = value.as(Double.self) {
                        AxisValueLabel {
                            Text("\(ms.formatted(.number.precision(.fractionLength(1)))) ms").font(.caption.monospacedDigit())
                                .frame(width: 44, alignment: .trailing)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let origin = geo[proxy.plotAreaFrame].origin
                                    let locationX = value.location.x - origin.x
                                    guard locationX >= 0, locationX <= proxy.plotAreaSize.width else { return }
                                    
                                    if let date: Date = proxy.value(atX: locationX) {
                                        if let closest = findClosestWorkerPoint(for: date, in: viewModel.dataPoints) {
                                            if selectedCpuPoint?.id != closest.id {
                                                HIGFeedback.impact(.light)
                                                selectedCpuPoint = closest
                                            }
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    selectedCpuPoint = nil
                                }
                        )
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
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
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                Text("\(ratio.formatted(.number.precision(.fractionLength(1)))) subrequests / req")
                    .font(.caption.weight(.semibold).monospacedDigit())
            }
            
            Divider()
            
            HStack {
                Text("Edge Functions Status")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.totalErrors == 0 ? "Fully Operational" : "\(viewModel.totalErrors) Invocations Failed")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(viewModel.totalErrors == 0 ? .green : .orange)
            }
            
            Divider()
            
            HStack {
                Text("Deployment Pipeline")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\((viewModel.deploymentSuccessRate / 100.0).formatted(.percent.precision(.fractionLength(1)))) Success Rate")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Helpers
    private func formattedPointDate(_ point: AggregatedWorkerDataPoint) -> String {
        let loc = DateFormatters.currentAppLocale
        if isHourlyData {
            return point.date.formatted(.dateTime.locale(loc).hour().minute())
        } else {
            return point.date.formatted(.dateTime.locale(loc).month().day())
        }
    }
    
    private func findClosestWorkerPoint(for date: Date, in points: [AggregatedWorkerDataPoint]) -> AggregatedWorkerDataPoint? {
        guard !points.isEmpty else { return nil }
        return points.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }
    
    private func formatNumber(_ num: Int) -> String {
        if num < 1000 { return num.formatted(.number) }
        let k = Double(num) / 1000.0
        if k < 1000 { return "\(k.formatted(.number.precision(.fractionLength(1))))K" }
        let m = k / 1000.0
        return "\(m.formatted(.number.precision(.fractionLength(2))))M"
    }
}
