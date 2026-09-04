import SwiftUI

struct RulesHubView: View {
    let zoneId: String

    var body: some View {
        List {
            Section {
                ZoneNavRowView(
                    title: "Transform Rules",
                    subtitle: "Modify request & response headers, rewrite URLs",
                    icon: "slider.horizontal.3",
                    color: .teal,
                    destination: TransformRulesView(zoneId: zoneId)
                )
                ZoneNavRowView(
                    title: "Cache Rules",
                    subtitle: "Custom cache behavior per URL pattern",
                    icon: "memorychip",
                    color: .indigo,
                    destination: CacheRulesView(zoneId: zoneId)
                )
                ZoneNavRowView(
                    title: "Redirect Rules",
                    subtitle: "Static & dynamic 301/302 URL redirects",
                    icon: "arrow.turn.up.right",
                    color: .blue,
                    destination: RedirectRulesView(zoneId: zoneId)
                )
                ZoneNavRowView(
                    title: "Edge Snippets",
                    subtitle: "Lightweight JavaScript on HTTP requests",
                    icon: "curlybraces",
                    color: .orange,
                    badgeText: "PRO",
                    destination: SnippetsListView(zoneId: zoneId)
                )
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Rules")
        .navigationBarTitleDisplayMode(.inline)
    }
}
