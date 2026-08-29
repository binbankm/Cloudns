import SwiftUI
import Charts

public struct WorkerAnalyticsView: View {
    public let accountId: String
    public let scriptName: String
    
    @StateObject private var viewModel: WorkerAnalyticsViewModel
    
    // Interactive Scrubbing States
    @State private var selectedPoint: AggregatedWorkerDataPoint?
    @State private var selectedCpuPoint: AggregatedWorkerDataPoint?
    
    public init(accountId: String, scriptName: String) {
        self.accountId = accountId
        self.scriptName = scriptName
        _viewModel = StateObject(wrappedValue: WorkerAnalyticsViewModel(accountId: accountId, scriptName: scriptName))
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
                ScrollView {
                    VStack(spacing: 16) {
                        metricsGrid
                            .redacted(reason: .placeholder)
                        invocationsLineChartCard
                            .redacted(reason: .placeholder)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            } else if viewModel.hasFetchedData && viewModel.dataPoints.isEmpty {
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
                                    title: "No Invocations Data",
                                    systemImage: "chart.xyaxis.line",
                                    description: "No Worker invocations recorded for \(scriptName) in the selected time range."
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
                        
                        // 3. Invocations & Errors 折线图 (Line & Area Chart with Scrubbing)
                        invocationsLineChartCard
                        
                        // 4. CPU Execution Latency 双折线图 (Line Chart P50 & P99 with Scrubbing)
                        cpuLatencyLineChartCard
                        
                        // 5. Performance Insights Card
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
        .navigationTitle("Worker Analytics")
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
            Image(systemName: "curlybraces.square.fill")
                .foregroundStyle(.purple)
                .font(.title3)
            
            Text(scriptName)
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
    
    // MARK: - 2. 4 Metrics Cards Grid
    private var metricsGrid: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                metricCard(
                    title: "Invocations",
                    value: formatNumber(viewModel.totalRequests),
                    icon: "bolt.horizontal.fill",
                    color: .purple,
                    badge: "\(formatNumber(viewModel.totalSubrequests)) Subrequests"
                )
                
                metricCard(
                    title: "Error Rate",
                    value: String(format: "%.1f%%", viewModel.errorRatePercentage),
                    icon: "exclamationmark.triangle.fill",
                    color: viewModel.errorRatePercentage > 0 ? .red : .green,
                    badge: "\(formatNumber(viewModel.totalErrors)) Errors"
                )
            }
            
            GridRow {
                metricCard(
                    title: "Median CPU",
                    value: String(format: "%.2f ms", viewModel.avgCpuP50),
                    icon: "timer",
                    color: .cyan,
                    badge: "50th Percentile"
                )
                
                metricCard(
                    title: "Max CPU (P99)",
                    value: String(format: "%.2f ms", viewModel.maxCpuP99),
                    icon: "speedometer",
                    color: .orange,
                    badge: "99th Percentile"
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
    
    // MARK: - 3. Invocations 折线图 (Line Chart with Live Scrubbing)
    private var invocationsLineChartCard: some View {
        let maxReq = viewModel.dataPoints.map { $0.requests }.max() ?? 10
        let yUpper = max(10.0, Double(maxReq) * 1.18)
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.purple)
                        Text("Invocations Traffic")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(formatNumber(selectedPoint?.requests ?? viewModel.totalRequests))
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
                            .fill(Color.purple)
                            .frame(width: 6, height: 6)
                        Text(dateStr)
                            .font(.caption2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.12))
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
                            colors: [Color.purple.opacity(0.32), Color.purple.opacity(0.01)],
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
                        .foregroundStyle(Color.purple.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                    
                    PointMark(
                        x: .value("Time", selected.date),
                        y: .value("Requests", selected.requests)
                    )
                    .symbol {
                        ZStack {
                            Circle()
                                .fill(Color.purple.opacity(0.25))
                                .frame(width: 16, height: 16)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .shadow(color: Color.purple, radius: 4)
                            Circle()
                                .stroke(Color.purple, lineWidth: 2)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
            .id("worker_invocations_\(viewModel.loadedDays)")
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
                            Text(formatNumber(count))
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
    
    // MARK: - 4. CPU Latency 双折线图 (Line Chart with Live Scrubbing)
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
                            Text(String(format: "%.2f ms", selected.cpuP50))
                                .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                                .foregroundStyle(.cyan)
                            Text("P50")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            
                            Text("•")
                                .foregroundStyle(.tertiary)
                            
                            Text(String(format: "%.2f ms", selected.cpuP99))
                                .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                                .foregroundStyle(.orange)
                            Text("P99")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack(alignment: .lastTextBaseline, spacing: 8) {
                            Text(String(format: "%.2f ms", viewModel.avgCpuP50))
                                .font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                                .foregroundStyle(.cyan)
                            Text("avg P50")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            
                            Text("•")
                                .foregroundStyle(.tertiary)
                            
                            Text(String(format: "%.2f ms", viewModel.maxCpuP99))
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
                        Text(dateStr)
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
            .id("worker_cpu_\(viewModel.loadedDays)")
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
                            Text(String(format: "%.1f ms", ms)).font(.caption.monospacedDigit())
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
    
    // MARK: - 5. Insights & Summary
    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Worker Performance Summary", systemImage: "sparkles")
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
                Text("Execution Health")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.totalErrors == 0 ? "Fully Operational" : "\(viewModel.totalErrors) Exceptions Detected")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(viewModel.totalErrors == 0 ? .green : .orange)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Helpers
    private func formattedPointDate(_ point: AggregatedWorkerDataPoint) -> String {
        if isHourlyData {
            return point.date.formatted(date: .omitted, time: .shortened)
        } else {
            return point.date.formatted(.dateTime.month().day())
        }
    }
    
    private func findClosestWorkerPoint(for date: Date, in points: [AggregatedWorkerDataPoint]) -> AggregatedWorkerDataPoint? {
        guard !points.isEmpty else { return nil }
        return points.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }
    
    private func formatNumber(_ num: Int) -> String {
        if num < 1000 { return "\(num)" }
        let k = Double(num) / 1000.0
        if k < 1000 { return String(format: "%.1fK", k) }
        let m = k / 1000.0
        return String(format: "%.2fM", m)
    }
}
