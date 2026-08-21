import SwiftUI
import WidgetKit

// MARK: - Worker Timeline Provider

public struct WorkerTimelineProvider: TimelineProvider {
    public typealias Entry = WorkerWidgetEntry
    
    public init() {}
    
    public func placeholder(in context: Context) -> WorkerWidgetEntry {
        WorkerWidgetEntry(date: Date(), snapshot: .placeholder)
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (WorkerWidgetEntry) -> Void) {
        let snap = WidgetDataStore.shared.loadWorkerSnapshot()
        completion(WorkerWidgetEntry(date: Date(), snapshot: snap))
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<WorkerWidgetEntry>) -> Void) {
        let snap = WidgetDataStore.shared.loadWorkerSnapshot()
        let entry = WorkerWidgetEntry(date: Date(), snapshot: snap)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Worker Widget Entry

public struct WorkerWidgetEntry: TimelineEntry {
    public let date: Date
    public let snapshot: WorkerWidgetSnapshot
    
    public init(date: Date, snapshot: WorkerWidgetSnapshot) {
        self.date = date
        self.snapshot = snapshot
    }
}

// MARK: - Worker Widget Definition

public struct WorkerOverviewWidget: Widget {
    public let kind: String = "WorkerOverviewWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkerTimelineProvider()) { entry in
            WorkerOverviewEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringResource("Worker Overview", comment: "Worker Widget Display Name"))
        .description(LocalizedStringResource("Monitor real-time requests, success rate, and CPU time for your Cloudflare Worker.", comment: "Worker Widget Description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Entry View

struct WorkerOverviewEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WorkerWidgetEntry
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                WorkerSmallWidgetView(snapshot: entry.snapshot)
                    .widgetBackground()
            case .systemMedium:
                WorkerMediumWidgetView(snapshot: entry.snapshot)
                    .widgetBackground()
            default:
                WorkerSmallWidgetView(snapshot: entry.snapshot)
                    .widgetBackground()
            }
        }
        .widgetURL(URL(string: "cloudns://developer/workers/\(entry.snapshot.id)"))
    }
}
