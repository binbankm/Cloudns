import SwiftUI

struct RulesHubView: View {
    let zoneId: String

    var body: some View {
        List {
            Section {
                ZoneNavRow(
                    title: "Transform Rules",
                    subtitle: "Modify request & response headers, rewrite URLs",
                    icon: "arrow.triangle.2.circlepath",
                    color: .teal,
                    destination: TransformRulesView(zoneId: zoneId)
                )
                ZoneNavRow(
                    title: "Cache Rules",
                    subtitle: "Custom cache behavior per URL pattern",
                    icon: "memorychip",
                    color: .indigo,
                    destination: CacheRulesView(zoneId: zoneId)
                )
                ZoneNavRow(
                    title: "Redirect Rules",
                    subtitle: "Static & dynamic 301/302 URL redirects",
                    icon: "arrow.turn.up.right",
                    color: .blue,
                    destination: RedirectRulesView(zoneId: zoneId)
                )
                ZoneNavRow(
                    title: "Edge Snippets",
                    subtitle: "Lightweight JavaScript on HTTP requests",
                    icon: "curlybraces",
                    color: .orange,
                    destination: SnippetsListView(zoneId: zoneId)
                )
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("Rules")
        .navigationBarTitleDisplayMode(.inline)
    }
}
