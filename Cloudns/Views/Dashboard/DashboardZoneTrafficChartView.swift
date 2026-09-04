import SwiftUI
import Charts

// MARK: - DashboardZoneTrafficChartView
// Apple HIG Compliant Interactive Swift Chart with Haptic Scrubbing

struct DashboardZoneTrafficChartView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var selectedPoint: FleetHourlyMetric?
    
    private var accentColor: Color {
        ThemeManager.shared.currentColor.color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Title, Live Cache Rate Badge
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Image(systemName: "globe.americas.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(accentColor)
                        
                        Text("Zone Traffic Analytics (24h)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    // Live Cache Rate Badge
                    if viewModel.averageCacheHitRate24h > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            
                            Text("\(viewModel.averageCacheHitRate24h.formatted(.percent.precision(.fractionLength(1)))) Cache")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
                
                // Big Metric Value Display with Selected Scrubbing Value
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(currentDisplayValue)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                    
                    if selectedPoint == nil {
                        Text("Total (24h)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if let selected = selectedPoint {
                        let themeColor = metricColor(viewModel.selectedChartMetric)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(themeColor)
                                .frame(width: 6, height: 6)
                            Text(selected.timeString)
                                .font(.caption2.monospacedDigit().weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(themeColor.opacity(0.14))
                        .clipShape(Capsule())
                    }
                }
                
                // Metric Picker Tabs
                Picker("Metric", selection: $viewModel.selectedChartMetric) {
                    ForEach(DashboardChartMetric.allCases) { metric in
                        Text(LocalizedStringKey(metric.title)).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Swift Chart Body
            chartBodyView
                .frame(height: 160)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }
    
    @ViewBuilder
    private var chartBodyView: some View {
        if viewModel.fleetMetrics.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                ProgressView()
                Text("Loading Analytics…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            let metrics = viewModel.fleetMetrics
            let themeColor = metricColor(viewModel.selectedChartMetric)
            
            Chart {
                ForEach(metrics) { item in
                    let value = valueForMetric(item, metric: viewModel.selectedChartMetric)
                    
                    // Area Glow
                    AreaMark(
                        x: .value("Time", item.date),
                        y: .value("Value", value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                themeColor.opacity(0.32),
                                themeColor.opacity(0.06),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Main Line
                    LineMark(
                        x: .value("Time", item.date),
                        y: .value("Value", value)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(themeColor)
                }
                
                // Scrubbing Rule Mark
                if let selected = selectedPoint {
                    let selectedVal = valueForMetric(selected, metric: viewModel.selectedChartMetric)
                    
                    RuleMark(x: .value("Selected", selected.date))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        .foregroundStyle(themeColor.opacity(0.6))
                    
                    PointMark(
                        x: .value("Selected", selected.date),
                        y: .value("SelectedValue", selectedVal)
                    )
                    .symbolSize(45)
                    .foregroundStyle(themeColor)
                }
            }
            .animation(.easeInOut(duration: 0.28), value: viewModel.selectedChartMetric)
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color(.separator).opacity(0.3))
                    AxisValueLabel(
                        format: DateFormatters.chartXAxisHourly,
                        collisionResolution: .greedy
                    )
                    .font(.caption2.weight(.medium).monospacedDigit())
                    .foregroundStyle(Color(.tertiaryLabel))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color(.separator).opacity(0.2))
                    AxisValueLabel {
                        if let dVal = value.as(Double.self) {
                            Text(MetricFormatters.compactNumber(dVal))
                                .font(.caption2.weight(.medium).monospacedDigit())
                                .foregroundStyle(Color(.tertiaryLabel))
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
                                .onChanged { drag in
                                    let frame = geo[proxy.plotAreaFrame]
                                    let locationX = drag.location.x - frame.origin.x
                                    guard locationX >= 0, locationX <= frame.width else { return }
                                    
                                    if let date = proxy.value(atX: locationX, as: Date.self) {
                                        // Find closest point by date
                                        if let closest = metrics.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                            if closest != selectedPoint {
                                                HIGFeedback.selection()
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
    }
    
    // MARK: - Helpers
    private func valueForMetric(_ item: FleetHourlyMetric, metric: DashboardChartMetric) -> Double {
        switch metric {
        case .requests:
            return item.requests
        case .bandwidth:
            return item.bytes
        case .threats:
            return item.threats
        }
    }
    
    private func metricColor(_ metric: DashboardChartMetric) -> Color {
        switch metric {
        case .requests: return accentColor
        case .bandwidth: return .purple
        case .threats: return .red
        }
    }
    
    private var currentDisplayValue: String {
        if let selected = selectedPoint {
            switch viewModel.selectedChartMetric {
            case .requests:
                return MetricFormatters.compactNumber(selected.requests)
            case .bandwidth:
                return ByteCountFormatter.string(fromByteCount: Int64(selected.bytes), countStyle: .binary)
            case .threats:
                return Int(selected.threats).formatted()
            }
        }
        
        switch viewModel.selectedChartMetric {
        case .requests:
            return MetricFormatters.compactNumber(viewModel.totalFleetRequests24h)
        case .bandwidth:
            return ByteCountFormatter.string(fromByteCount: Int64(viewModel.totalFleetBandwidth24h), countStyle: .binary)
        case .threats:
            return Int(viewModel.totalThreats24h).formatted()
        }
    }
}
