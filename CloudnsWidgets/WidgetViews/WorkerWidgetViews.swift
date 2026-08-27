import SwiftUI
import WidgetKit

// MARK: - Worker Small Widget View

public struct WorkerSmallWidgetView: View {
    let snapshot: WorkerWidgetSnapshot
    
    public init(snapshot: WorkerWidgetSnapshot) {
        self.snapshot = snapshot
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: Worker Icon + Name + Active Dot
            HStack(spacing: 5) {
                Image(systemName: "bolt.badge.automatic.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                
                Text(snapshot.name)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer(minLength: 0)
                
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)
            }
            
            Spacer(minLength: 0)
            
            // 2x2 Metric Grid (Requests, Success Rate, CPU Time, Errors)
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    metricCard(
                        title: "Requests",
                        value: snapshot.formattedRequests,
                        icon: "play.circle.fill",
                        color: .orange
                    )
                    
                    metricCard(
                        title: "Success",
                        value: snapshot.formattedSuccessRate,
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                }
                
                HStack(spacing: 6) {
                    metricCard(
                        title: "CPU Time",
                        value: snapshot.formattedCpuTime,
                        icon: "stopwatch.fill",
                        color: .blue
                    )
                    
                    metricCard(
                        title: "Errors",
                        value: "\(snapshot.errors24h)",
                        icon: "exclamationmark.triangle.fill",
                        color: snapshot.errors24h > 0 ? .red : .secondary
                    )
                }
            }
        }
        .padding(12)
        .widgetURL(URL(string: "cloudns://developer/workers/\(snapshot.id)"))
    }
    
    @ViewBuilder
    private func metricCard(title: LocalizedStringKey, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6)
        .padding(.vertical, 4.5)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Worker Medium Widget View

public struct WorkerMediumWidgetView: View {
    let snapshot: WorkerWidgetSnapshot
    
    public init(snapshot: WorkerWidgetSnapshot) {
        self.snapshot = snapshot
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            // Left Column: Worker Identity & Badge
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.badge.automatic.fill")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.orange)
                    
                    Text(snapshot.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Text("Cloudflare Worker")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer(minLength: 0)
                
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Active")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 2) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 8))
                        Text("V8 Edge")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .padding(.vertical, 2)
            
            // Right Column: 2x2 Metric Grid
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    metricTile(
                        title: "24h Invocations",
                        value: snapshot.formattedRequests,
                        icon: "play.circle.fill",
                        color: .orange
                    )
                    
                    metricTile(
                        title: "Success Rate",
                        value: snapshot.formattedSuccessRate,
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                }
                
                HStack(spacing: 6) {
                    metricTile(
                        title: "Avg CPU Time",
                        value: snapshot.formattedCpuTime,
                        icon: "stopwatch.fill",
                        color: .blue
                    )
                    
                    metricTile(
                        title: "24h Errors",
                        value: "\(snapshot.errors24h)",
                        icon: "exclamationmark.triangle.fill",
                        color: snapshot.errors24h > 0 ? .red : .secondary
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .widgetURL(URL(string: "cloudns://developer/workers/\(snapshot.id)"))
    }
    
    @ViewBuilder
    private func metricTile(title: LocalizedStringKey, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
