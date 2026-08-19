import SwiftUI
import WidgetKit

// MARK: - Quick Actions Timeline Provider

struct QuickActionsTimelineProvider: TimelineProvider {
    typealias Entry = QuickActionsWidgetEntry
    
    func placeholder(in context: Context) -> QuickActionsWidgetEntry {
        QuickActionsWidgetEntry(date: Date())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuickActionsWidgetEntry) -> Void) {
        completion(QuickActionsWidgetEntry(date: Date()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickActionsWidgetEntry>) -> Void) {
        let entry = QuickActionsWidgetEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Quick Actions Widget Entry

struct QuickActionsWidgetEntry: TimelineEntry {
    let date: Date
}

// MARK: - Quick Actions Widget

public struct QuickActionsWidget: Widget {
    public let kind: String = "QuickActionsWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickActionsTimelineProvider()) { _ in
            QuickActionsWidgetView()
                .widgetBackground()
        }
        .configurationDisplayName("Cloudns Quick Deck")
        .description("Instant one-tap access to DoH Dig, Trace Route, CF Status, and IP Ranges.")
        .supportedFamilies([
            .systemMedium
        ])
    }
}
