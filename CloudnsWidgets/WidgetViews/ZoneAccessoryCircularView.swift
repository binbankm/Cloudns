import SwiftUI
import WidgetKit

// MARK: - ZoneAccessoryCircularView

public struct ZoneAccessoryCircularView: View {
    let snapshot: ZoneWidgetSnapshot
    
    public init(snapshot: ZoneWidgetSnapshot) {
        self.snapshot = snapshot
    }
    
    public var body: some View {
        Gauge(value: min(1.0, max(0.0, snapshot.cachedRatio))) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 10))
                .widgetAccentable()
        } currentValueLabel: {
            Text(snapshot.formattedCachedRatio)
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetURL(URL(string: "cloudns://zone/\(snapshot.id)"))
    }
}
