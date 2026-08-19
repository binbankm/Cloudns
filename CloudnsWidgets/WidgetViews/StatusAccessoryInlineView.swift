import SwiftUI
import WidgetKit

// MARK: - StatusAccessoryInlineView

public struct StatusAccessoryInlineView: View {
    let snapshot: CFStatusWidgetSnapshot
    
    public init(snapshot: CFStatusWidgetSnapshot) {
        self.snapshot = snapshot
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: snapshot.isOperational ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .widgetAccentable()
            if snapshot.isOperational {
                Text("Cloudflare: All Normal")
            } else {
                Text(snapshot.description)
            }
        }
        .widgetURL(URL(string: "cloudns://tools/status"))
    }
}
