import SwiftUI
import WidgetKit

// MARK: - Pages Small Widget View

public struct PagesSmallWidgetView: View {
    let snapshot: PagesWidgetSnapshot
    
    public init(snapshot: PagesWidgetSnapshot) {
        self.snapshot = snapshot
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: Pages Icon + Project Name
            HStack(spacing: 5) {
                Image(systemName: "doc.text.image.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.purple)
                
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
            
            // 2x2 Metric Grid (Requests, Errors, Branch, Status)
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    metricCard(
                        title: "Requests",
                        value: snapshot.formattedRequests,
                        icon: "arrow.down.circle.fill",
                        color: .purple
                    )
                    
                    metricCard(
                        title: "Branch",
                        value: snapshot.productionBranch,
                        icon: "arrow.triangle.branch",
                        color: .blue
                    )
                }
                
                HStack(spacing: 6) {
                    metricCard(
                        title: "Status",
                        value: snapshot.latestStatus.capitalized,
                        icon: "checkmark.seal.fill",
                        color: .green
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
        .widgetURL(URL(string: "cloudns://developer/pages/\(snapshot.id)"))
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

// MARK: - Pages Medium Widget View

public struct PagesMediumWidgetView: View {
    let snapshot: PagesWidgetSnapshot
    
    public init(snapshot: PagesWidgetSnapshot) {
        self.snapshot = snapshot
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            // Left Column: Project Identity & Subdomain
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.image.fill")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.purple)
                    
                    Text(snapshot.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Text(snapshot.subdomain)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
                
                HStack(spacing: 5) {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Production")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 8))
                        Text(snapshot.productionBranch)
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.12))
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
                        title: "24h Requests",
                        value: snapshot.formattedRequests,
                        icon: "arrow.down.circle.fill",
                        color: .purple
                    )
                    
                    metricTile(
                        title: "Build Status",
                        value: snapshot.latestStatus.capitalized,
                        icon: "checkmark.seal.fill",
                        color: .green
                    )
                }
                
                HStack(spacing: 6) {
                    metricTile(
                        title: "Prod Branch",
                        value: snapshot.productionBranch,
                        icon: "arrow.triangle.branch",
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
        .widgetURL(URL(string: "cloudns://developer/pages/\(snapshot.id)"))
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
