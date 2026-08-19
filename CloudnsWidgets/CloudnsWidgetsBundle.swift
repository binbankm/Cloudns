import SwiftUI
import WidgetKit

// MARK: - Cloudns Widgets Bundle

@main
public struct CloudnsWidgetsBundle: WidgetBundle {
    public init() {}
    
    public var body: some Widget {
        ZoneOverviewWidget()
        SystemStatusWidget()
        QuickActionsWidget()
    }
}
