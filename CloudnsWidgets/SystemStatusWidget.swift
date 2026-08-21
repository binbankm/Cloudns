import SwiftUI
import WidgetKit

// MARK: - Status Timeline Provider

struct StatusTimelineProvider: TimelineProvider {
    typealias Entry = StatusWidgetEntry
    
    func placeholder(in context: Context) -> StatusWidgetEntry {
        StatusWidgetEntry(date: Date(), snapshot: .placeholder)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (StatusWidgetEntry) -> Void) {
        let snapshot = WidgetDataStore.shared.loadStatusSnapshot()
        completion(StatusWidgetEntry(date: Date(), snapshot: snapshot))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<StatusWidgetEntry>) -> Void) {
        let snapshot = WidgetDataStore.shared.loadStatusSnapshot()
        let currentDate = Date()
        let interval: TimeInterval = snapshot.description.isEmpty ? 5 : 900
        let nextUpdate = currentDate.addingTimeInterval(interval)
        let entry = StatusWidgetEntry(date: currentDate, snapshot: snapshot)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Status Widget Entry

struct StatusWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: CFStatusWidgetSnapshot
}

// MARK: - System Status Widget

public struct SystemStatusWidget: Widget {
    public let kind: String = "SystemStatusWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatusTimelineProvider()) { entry in
            StatusOverviewEntryView(entry: entry)
        }
        .configurationDisplayName("Cloudflare Status")
        .description("Track Cloudflare global edge network health and incident alerts.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryInline
        ])
    }
}

// MARK: - Entry View

struct StatusOverviewEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: StatusWidgetEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            StatusSmallWidgetView(snapshot: entry.snapshot)
                .widgetBackground()
        case .systemMedium:
            StatusMediumWidgetView(snapshot: entry.snapshot)
                .widgetBackground()
        case .accessoryInline:
            StatusAccessoryInlineView(snapshot: entry.snapshot)
                .accessoryWidgetBackground()
        default:
            StatusSmallWidgetView(snapshot: entry.snapshot)
                .widgetBackground()
        }
    }
}
