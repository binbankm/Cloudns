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
            let width = max(1, proxy.size.width)
            let height = max(1, proxy.size.height)
            let validValues = data.map { max(0, $0) }
            let points = normalizedPoints(for: validValues, in: CGSize(width: width, height: height))
            
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
                                colors: [lineColor.opacity(0.65), lineColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: lineColor.opacity(0.35), radius: 2.5, x: 0, y: 1)
                    
                    // 末端高亮微光指示点
                    if let last = points.last {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 3.5, height: 3.5)
                            .shadow(color: lineColor, radius: 2)
                            .position(last)
                    }
                } else {
                    // 无数据或单点时的极简基线
                    Path { p in
                        p.move(to: CGPoint(x: 2, y: height * 0.75))
                        p.addLine(to: CGPoint(x: width - 2, y: height * 0.75))
                    }
                    .stroke(lineColor.opacity(0.22), style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
                }
            }
            .clipped()
        }
    }
    
    private func normalizedPoints(for values: [Double], in size: CGSize) -> [CGPoint] {
        guard values.count > 1 else { return [] }
        
        let maxVal = values.max() ?? 1.0
        let minVal = values.min() ?? 0.0
        let range = max(maxVal - minVal, 1.0)
        
        // 留出 2pt 边缘安全间距，防止线条和圆点超出边界
        let horizontalPadding: CGFloat = 2.0
        let usableWidth = max(1, size.width - horizontalPadding * 2)
        let stepX = usableWidth / CGFloat(values.count - 1)
        
        let usableHeight = size.height * 0.70
        let offsetY = size.height * 0.15
        
        return values.enumerated().map { index, val in
            let normY = (val - minVal) / range
            let y = size.height - (CGFloat(normY) * usableHeight + offsetY)
            let x = horizontalPadding + CGFloat(index) * stepX
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
    
    @Environment(\.redactionReasons) private var redactionReasons
    
    private var isRedacted: Bool {
        redactionReasons.contains(.placeholder)
    }
    
    public var body: some View {
        if isRedacted {
            Capsule()
                .fill(Color(.tertiarySystemFill))
                .frame(width: 48, height: 16)
                .accessibilityHidden(true)
        } else {
            let points = cached?.points ?? []
            let total = cached?.totalRequests ?? 0
            
            HStack(spacing: 5) {
                ZoneTrafficSparklineView(
                    data: points,
                    lineColor: sparklineColor(total: total),
                    lineWidth: 1.5
                )
                .frame(width: 44, height: 22)
                
                if total > 0 {
                    Text(formatMetric(total))
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .accessibilityHidden(true)
        }
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
