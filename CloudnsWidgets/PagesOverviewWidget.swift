import SwiftUI
import WidgetKit

// MARK: - Pages Timeline Provider

public struct PagesTimelineProvider: TimelineProvider {
    public typealias Entry = PagesWidgetEntry
    
    public init() {}
    
    public func placeholder(in context: Context) -> PagesWidgetEntry {
        PagesWidgetEntry(date: Date(), snapshot: .placeholder)
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (PagesWidgetEntry) -> Void) {
        let snap = WidgetDataStore.shared.loadPagesSnapshot()
        completion(PagesWidgetEntry(date: Date(), snapshot: snap))
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<PagesWidgetEntry>) -> Void) {
        let snap = WidgetDataStore.shared.loadPagesSnapshot()
        let entry = PagesWidgetEntry(date: Date(), snapshot: snap)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Pages Widget Entry

public struct PagesWidgetEntry: TimelineEntry {
    public let date: Date
    public let snapshot: PagesWidgetSnapshot
    
    public init(date: Date, snapshot: PagesWidgetSnapshot) {
        self.date = date
        self.snapshot = snapshot
    }
}

// MARK: - Pages Widget Definition

public struct PagesOverviewWidget: Widget {
    public let kind: String = "PagesOverviewWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PagesTimelineProvider()) { entry in
            PagesOverviewEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringResource("Pages Overview", comment: "Pages Widget Display Name"))
        .description(LocalizedStringResource("Monitor deployment status, production branch, and traffic for your Cloudflare Pages project.", comment: "Pages Widget Description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Entry View

struct PagesOverviewEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: PagesWidgetEntry
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                PagesSmallWidgetView(snapshot: entry.snapshot)
                    .widgetBackground()
            case .systemMedium:
                PagesMediumWidgetView(snapshot: entry.snapshot)
                    .widgetBackground()
            default:
                PagesSmallWidgetView(snapshot: entry.snapshot)
                    .widgetBackground()
            }
        }
        .widgetURL(URL(string: "cloudns://developer/pages/\(entry.snapshot.id)"))
    }
}
