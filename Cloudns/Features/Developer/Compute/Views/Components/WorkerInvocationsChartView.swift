import SwiftUI
import Charts

// MARK: - WorkerInvocationsChartView

struct WorkerInvocationsChartView: View {
    // MARK: - Properties
    let dataPoints: [AggregatedWorkerDataPoint]
    let totalRequests: Int
    let loadedDays: Int
    let chartXRange: ClosedRange<Date>
    let isHourlyData: Bool
    @Binding var selectedPoint: AggregatedWorkerDataPoint?
    
    // MARK: - Body
    var body: some View {
        let maxReq = dataPoints.map { $0.requests }.max() ?? 10
        let yUpper = max(10.0, Double(maxReq) * 1.18)
        
        VStack(alignment: .leading, spacing: 10) {
            headerRow
            
            Chart {
                ForEach(dataPoints) { pt in
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
                        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.xs, style: .continuous))
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
                        selectedPointSymbol
                    }
                }
            }
            .id("worker_invocations_\(loadedDays)")
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
                chartInteractionOverlay(proxy: proxy)
            }
        }
        .padding(16)
        .background(CloudnsColor.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.lg))
    }
    
    // MARK: - Private Views
    private var headerRow: some View {
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
                    Text(formatNumber(selectedPoint?.requests ?? totalRequests))
                        .font(.system(.title, design: .rounded).weight(.bold))
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
    }
    
    private var selectedPointSymbol: some View {
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
                                    if selectedPoint?.id != closest.id {
                                        HapticManager.impact(.light)
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
    
    private func formatNumber(_ num: Int) -> String {
        if num < 1000 { return "\(num)" }
        let k = Double(num) / 1000.0
        if k < 1000 { return String(format: "%.1fK", k) }
        let m = k / 1000.0
        return String(format: "%.2fM", m)
    }
}
