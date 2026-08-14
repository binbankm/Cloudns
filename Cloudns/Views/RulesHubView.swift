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
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Rules")
        .navigationBarTitleDisplayMode(.inline)
    }
}
