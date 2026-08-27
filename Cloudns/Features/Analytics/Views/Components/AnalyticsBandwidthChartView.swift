import SwiftUI
import Charts

// MARK: - AnalyticsBandwidthChartView

struct AnalyticsBandwidthChartView: View {
    // MARK: - Properties
    let dataPoints: [AnalyticsDataPoint]
    let totalBandwidthBytes: Int
    let formatBytes: (Int) -> String
    let chartXRange: ClosedRange<Date>
    let isHourlyData: Bool
    @Binding var selectedBandwidthPoint: AnalyticsDataPoint?
    
    // MARK: - Body
    var body: some View {
        let maxBytes = dataPoints.map { $0.sum.bytes }.max() ?? 1024
        let yUpper = max(1024.0, Double(maxBytes) * 1.18)
        
        VStack(alignment: .leading, spacing: CloudnsSpacing.smMd) {
            headerRow
            
            Chart {
                ForEach(dataPoints) { point in
                    let ptDate = dateFromString(point.dimensions.datetime ?? point.dimensions.date ?? "")
                    let isSelected = selectedBandwidthPoint?.id == point.id
                    
                    BarMark(
                        x: .value("Date", ptDate),
                        y: .value("Bytes", point.sum.bytes),
                        width: .fixed(8)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: isSelected
                                ? [Color.purple.opacity(0.95), Color.purple]
                                : [Color.purple.opacity(0.65), Color.purple.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.xs, style: .continuous))
                }
                
                if let selected = selectedBandwidthPoint {
                    let selDate = dateFromString(selected.dimensions.datetime ?? selected.dimensions.date ?? "")
                    RuleMark(x: .value("Date", selDate))
                        .foregroundStyle(Color.purple.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                }
            }
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
                    if let bytes = value.as(Int.self) {
                        AxisValueLabel {
                            Text(formatBytes(bytes))
                                .frame(width: 52, alignment: .trailing)
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
                    Image(systemName: "chart.bar.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.purple)
                    Text("Bandwidth Usage")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                
                HStack(alignment: .lastTextBaseline, spacing: CloudnsSpacing.sm) {
                    Text(formatBytes(selectedBandwidthPoint?.sum.bytes ?? totalBandwidthBytes))
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(.primary)
                    Text(selectedBandwidthPoint != nil ? "transferred" : "total")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if let selected = selectedBandwidthPoint {
                let dateStr = formattedPointDate(selected)
                HStack(spacing: CloudnsSpacing.xs) {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 6, height: 6)
                    Text(dateStr)
                        .font(.caption2.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, CloudnsSpacing.sm)
                .padding(.vertical, CloudnsSpacing.xs)
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
                                    if selectedBandwidthPoint?.id != closest.id {
                                        HapticManager.impact(.light)
                                        selectedBandwidthPoint = closest
                                    }
                                }
                            }
                        }
                        .onEnded { _ in
                            selectedBandwidthPoint = nil
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
}
