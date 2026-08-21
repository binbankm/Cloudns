import SwiftUI
import WidgetKit

// MARK: - Zone Timeline Provider

struct ZoneTimelineProvider: TimelineProvider {
    typealias Entry = ZoneWidgetEntry
    
    func placeholder(in context: Context) -> ZoneWidgetEntry {
        ZoneWidgetEntry(date: Date(), snapshot: .placeholder)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ZoneWidgetEntry) -> Void) {
        let snapshot = WidgetDataStore.shared.loadZoneSnapshot()
        completion(ZoneWidgetEntry(date: Date(), snapshot: snapshot))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ZoneWidgetEntry>) -> Void) {
        let snapshot = WidgetDataStore.shared.loadZoneSnapshot()
        let currentDate = Date()
        let interval: TimeInterval = (snapshot.name == "example.com" || snapshot.id == "placeholder-zone-id") ? 5 : 900
        let nextUpdate = currentDate.addingTimeInterval(interval)
        let entry = ZoneWidgetEntry(date: currentDate, snapshot: snapshot)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Zone Widget Entry

struct ZoneWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: ZoneWidgetSnapshot
}

// MARK: - Zone Overview Widget

public struct ZoneOverviewWidget: Widget {
    public let kind: String = "ZoneOverviewWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZoneTimelineProvider()) { entry in
            ZoneOverviewEntryView(entry: entry)
        }
        .configurationDisplayName("Domain Analytics")
        .description("Monitor your Cloudflare zone traffic, requests, and security status in real-time.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryCircular
        ])
    }
}

// MARK: - Entry View

struct ZoneOverviewEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: ZoneWidgetEntry
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                ZoneSmallWidgetView(snapshot: entry.snapshot)
                    .widgetBackground()
            case .systemMedium:
                ZoneMediumWidgetView(snapshot: entry.snapshot)
                    .widgetBackground()
            case .accessoryRectangular:
                ZoneAccessoryRectangularView(snapshot: entry.snapshot)
                    .accessoryWidgetBackground()
            case .accessoryCircular:
                ZoneAccessoryCircularView(snapshot: entry.snapshot)
                    .accessoryWidgetBackground()
            default:
                ZoneSmallWidgetView(snapshot: entry.snapshot)
                    .widgetBackground()
            }
        }
        .widgetURL(URL(string: "cloudns://zone/\(entry.snapshot.id)"))
    }
}

// MARK: - Widget Background Extension

extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) {
                Color(.systemBackground)
            }
        } else {
            self.background(Color(.systemBackground))
        }
    }
    
    @ViewBuilder
    func accessoryWidgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(.clear, for: .widget)
        } else {
            self
        }
    }
}
