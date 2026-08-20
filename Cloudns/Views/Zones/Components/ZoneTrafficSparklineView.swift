import SwiftUI

// MARK: - ZoneTrafficSparklineView

public struct ZoneTrafficSparklineView: View {
    let data: [Double]
    let lineColor: Color
    let lineWidth: CGFloat
    let showGradientFill: Bool
    
    public init(
        data: [Double],
        lineColor: Color = .blue,
        lineWidth: CGFloat = 1.8,
        showGradientFill: Bool = true
    ) {
        self.data = data
        self.lineColor = lineColor
        self.lineWidth = lineWidth
        self.showGradientFill = showGradientFill
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let points = normalizedPoints(for: data, in: CGSize(width: width, height: height))
            
            ZStack {
                if showGradientFill && points.count > 1 {
                    path(for: points, closedToBottom: true, height: height, width: width)
                        .fill(
                            LinearGradient(
                                colors: [lineColor.opacity(0.35), lineColor.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                if points.count > 1 {
                    path(for: points, closedToBottom: false, height: height, width: width)
                        .stroke(
                            LinearGradient(
                                colors: [lineColor.opacity(0.7), lineColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                        )
                } else {
                    // Minimal flat baseline when no traffic or single point
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: height * 0.75))
                        p.addLine(to: CGPoint(x: width, y: height * 0.75))
                    }
                    .stroke(lineColor.opacity(0.20), style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
                }
            }
        }
    }
    
    private func normalizedPoints(for values: [Double], in size: CGSize) -> [CGPoint] {
        guard values.count > 1 else { return [] }
        
        let validValues = values.map { max(0, $0) }
        let maxVal = validValues.max() ?? 1.0
        let minVal = validValues.min() ?? 0.0
        let range = max(maxVal - minVal, 1.0)
        
        let stepX = size.width / CGFloat(validValues.count - 1)
        let usableHeight = size.height * 0.75
        let offsetY = size.height * 0.12
        
        return validValues.enumerated().map { index, val in
            let normY = (val - minVal) / range
            let y = size.height - (CGFloat(normY) * usableHeight + offsetY)
            let x = CGFloat(index) * stepX
            return CGPoint(x: x, y: y)
        }
    }
    
    private func path(for points: [CGPoint], closedToBottom: Bool, height: CGFloat, width: CGFloat) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        
        path.move(to: points[0])
        
        for i in 1..<points.count {
            let p0 = points[i - 1]
            let p1 = points[i]
            let midPoint = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
            let controlPoint1 = CGPoint(x: (midPoint.x + p0.x) / 2, y: p0.y)
            let controlPoint2 = CGPoint(x: (midPoint.x + p1.x) / 2, y: p1.y)
            
            path.addCurve(to: midPoint, control1: controlPoint1, control2: CGPoint(x: midPoint.x, y: p0.y))
            path.addCurve(to: p1, control1: CGPoint(x: midPoint.x, y: p1.y), control2: controlPoint2)
        }
        
        if closedToBottom {
            path.addLine(to: CGPoint(x: points.last?.x ?? width, y: height))
            path.addLine(to: CGPoint(x: points[0].x, y: height))
            path.closeSubpath()
        }
        
        return path
    }
}

// MARK: - ZoneRowSparklineView (Instant SWR & Batch Cache Binding)

public struct ZoneRowSparklineView: View {
    let zoneId: String
    let cached: ZoneSparklineCache?
    
    public init(zoneId: String, cached: ZoneSparklineCache? = nil) {
        self.zoneId = zoneId
        self.cached = cached
    }
    
    public var body: some View {
        let points = cached?.points ?? []
        let total = cached?.totalRequests ?? 0
        
        HStack(spacing: 6) {
            ZoneTrafficSparklineView(
                data: points,
                lineColor: sparklineColor(total: total),
                lineWidth: 1.6
            )
            .frame(width: 52, height: 24)
            
            if total > 0 {
                Text(formatMetric(total))
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .accessibilityHidden(true)
    }
    
    private func sparklineColor(total: Int) -> Color {
        if total > 10_000 {
            return .orange
        } else if total > 100 {
            return .blue
        } else {
            return .teal
        }
    }
    
    private func formatMetric(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000.0)
        } else if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000.0)
        } else {
            return "\(value)"
        }
    }
}

// MARK: - Cache Model
public struct ZoneSparklineCache: Codable, Sendable {
    public let points: [Double]
    public let totalRequests: Int
    
    public init(points: [Double], totalRequests: Int) {
        self.points = points
        self.totalRequests = totalRequests
    }
}
