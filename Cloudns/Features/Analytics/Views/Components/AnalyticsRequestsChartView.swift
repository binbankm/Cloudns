import SwiftUI
import Charts

// MARK: - AnalyticsRequestsChartView

struct AnalyticsRequestsChartView: View {
    // MARK: - Properties
    let dataPoints: [AnalyticsDataPoint]
    let totalRequests: Int
    let chartXRange: ClosedRange<Date>
    let isHourlyData: Bool
    @Binding var selectedPoint: AnalyticsDataPoint?
    
    // MARK: - Body
    var body: some View {
        let maxReq = dataPoints.map { $0.sum.requests }.max() ?? 10
        let yUpper = max(10.0, Double(maxReq) * 1.18)
        
        VStack(alignment: .leading, spacing: 10) {
            headerRow
            
            Chart {
                ForEach(dataPoints) { point in
                    let ptDate = dateFromString(point.dimensions.datetime ?? point.dimensions.date ?? "")
                    
                    AreaMark(
                        x: .value("Date", ptDate),
                        y: .value("Requests", point.sum.requests)
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
                        x: .value("Date", ptDate),
                        y: .value("Requests", point.sum.requests)
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                }
                
                if let selected = selectedPoint {
                    let selDate = dateFromString(selected.dimensions.datetime ?? selected.dimensions.date ?? "")
                    RuleMark(x: .value("Date", selDate))
                        .foregroundStyle(Color.blue.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                    
                    PointMark(
                        x: .value("Date", selDate),
                        y: .value("Requests", selected.sum.requests)
                    )
                    .symbol {
                        selectedPointSymbol
                    }
                }
            }
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
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Private Views
    private var headerRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.blue)
                    Text("Requests Traffic")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(formatNumber(selectedPoint?.sum.requests ?? totalRequests))
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(.primary)
                    Text(selectedPoint != nil ? "requests" : "total")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let selected = selectedPoint {
                let dateStr = formattedPointDate(selected)
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                    Text(dateStr)
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
    }
    
    private var selectedPointSymbol: some View {
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
    private func dateFromString(_ str: String) -> Date {
        DateFormatters.parseChartDate(str)
    }
    
    private func formattedPointDate(_ point: AnalyticsDataPoint) -> String {
        let str = point.dimensions.datetime ?? point.dimensions.date ?? ""
        let date = dateFromString(str)
        if isHourlyData {
            return date.formatted(date: .omitted, time: .shortened)
        } else {
            return date.formatted(.dateTime.month().day())
        }
    }
    
    private func findClosestPoint(for date: Date, in points: [AnalyticsDataPoint]) -> AnalyticsDataPoint? {
        guard !points.isEmpty else { return nil }
        return points.min(by: {
            let d1 = dateFromString($0.dimensions.datetime ?? $0.dimensions.date ?? "")
            let d2 = dateFromString($1.dimensions.datetime ?? $1.dimensions.date ?? "")
            return abs(d1.timeIntervalSince(date)) < abs(d2.timeIntervalSince(date))
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
