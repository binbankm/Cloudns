import SwiftUI
import Charts

// MARK: - WorkerCPULatencyChartView

struct WorkerCPULatencyChartView: View {
    // MARK: - Properties
    let dataPoints: [AggregatedWorkerDataPoint]
    let avgCpuP50: Double
    let maxCpuP99: Double
    let loadedDays: Int
    let chartXRange: ClosedRange<Date>
    let isHourlyData: Bool
    @Binding var selectedCpuPoint: AggregatedWorkerDataPoint?
    
    // MARK: - Body
    var body: some View {
        let maxCpu = dataPoints.map { max($0.cpuP50, $0.cpuP99) }.max() ?? 10.0
        let yUpper = max(2.0, maxCpu * 1.18)
        
        VStack(alignment: .leading, spacing: CloudnsSpacing.smMd) {
            headerRow
            
            Chart {
                ForEach(dataPoints) { pt in
                    LineMark(
                        x: .value("Time", pt.date),
                        y: .value("CPU P50", pt.cpuP50)
                    )
                    .foregroundStyle(CloudnsColor.database)
                    .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                    
                    LineMark(
                        x: .value("Time", pt.date),
                        y: .value("CPU P99", pt.cpuP99)
                    )
                    .foregroundStyle(CloudnsColor.brandAccent)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [4, 3]))
                    .interpolationMethod(.monotone)
                }
                
                if let selected = selectedCpuPoint {
                    RuleMark(x: .value("Time", selected.date))
                        .foregroundStyle(CloudnsColor.database.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                    
                    PointMark(
                        x: .value("Time", selected.date),
                        y: .value("CPU P50", selected.cpuP50)
                    )
                    .symbol {
                        Circle()
                            .fill(Color.white)
                            .frame(width: CloudnsSize.iconMini, height: CloudnsSize.iconMini)
                            .overlay(Circle().stroke(CloudnsColor.database, lineWidth: 2))
                            .shadow(color: CloudnsColor.database, radius: 4)
                    }
                }
            }
            .id("worker_cpu_\(loadedDays)")
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
                            Text(String(format: "%.1f ms", ms))
                                .frame(width: 44, alignment: .trailing)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                chartInteractionOverlay(proxy: proxy)
            }
        }
        .padding(CloudnsSpacing.md)
        .background(CloudnsColor.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.lg))
    }
    
    // MARK: - Private Views
    private var headerRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: CloudnsSpacing.sm) {
                    Image(systemName: "bolt.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.cyan)
                    Text("CPU Execution Time")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                
                if let selected = selectedCpuPoint {
                    HStack(alignment: .lastTextBaseline, spacing: CloudnsSpacing.sm) {
                        Text(String(format: "%.2f ms", selected.cpuP50))
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(.cyan)
                        Text("P50")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        
                        Text("•")
                            .foregroundStyle(.tertiary)
                        
                        Text(String(format: "%.2f ms", selected.cpuP99))
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(CloudnsColor.brandAccent)
                        Text("P99")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack(alignment: .lastTextBaseline, spacing: CloudnsSpacing.sm) {
                        Text(String(format: "%.2f ms", avgCpuP50))
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(.cyan)
                        Text("avg P50")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        
                        Text("•")
                            .foregroundStyle(.tertiary)
                        
                        Text(String(format: "%.2f ms", maxCpuP99))
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(CloudnsColor.brandAccent)
                        Text("max P99")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if let selected = selectedCpuPoint {
                let dateStr = formattedPointDate(selected)
                HStack(spacing: CloudnsSpacing.xs) {
                    Circle()
                        .fill(CloudnsColor.database)
                        .frame(width: 6, height: 6)
                    Text(dateStr)
                        .font(.caption2.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, CloudnsSpacing.sm)
                .padding(.vertical, CloudnsSpacing.xs)
                .background(CloudnsColor.databaseMuted)
                .clipShape(Capsule())
            } else {
                HStack(spacing: CloudnsSpacing.sm) {
                    Label("P50", systemImage: "circle.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.cyan)
                    Label("P99", systemImage: "circle.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(CloudnsColor.brandAccent)
                }
            }
        }
        .frame(minHeight: 48)
    }
    
    private func chartInteractionOverlay(proxy: ChartProxy) -> some View {
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
                                if let closest = findClosestPoint(for: date, in: dataPoints) {
                                    if selectedCpuPoint?.id != closest.id {
                                        HapticManager.impact(.light)
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
    
    // MARK: - Helpers
    private func formattedPointDate(_ point: AggregatedWorkerDataPoint) -> String {
        if isHourlyData {
            return point.date.formatted(date: .omitted, time: .shortened)
        } else {
            return point.date.formatted(.dateTime.month().day())
        }
    }
    
    private func findClosestPoint(for date: Date, in points: [AggregatedWorkerDataPoint]) -> AggregatedWorkerDataPoint? {
        guard !points.isEmpty else { return nil }
        return points.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }
}
