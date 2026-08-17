import SwiftUI

struct SecurityHubView: View {
    let zoneId: String

    var body: some View {
        List {
            Section(header: Text("Events")) {
                ZoneNavRow(
                    title: "Security Events",
                    subtitle: "Firewall activity & triggered rules",
                    icon: "exclamationmark.shield.fill",
                    color: .purple,
                    destination: SecurityEventsView(zoneId: zoneId)
                )
            }

            Section(header: Text("Rules")) {
                ZoneNavRow(
                    title: "WAF",
                    subtitle: "Custom rules, managed rules",
                    icon: "shield.lefthalf.filled",
                    color: .red,
                    destination: WAFCustomRulesView(zoneId: zoneId)
                )
                ZoneNavRow(
                    title: "Rate Limiting",
                    subtitle: "Throttle excessive request rates",
                    icon: "speedometer",
                    color: .orange,
                    destination: RateLimitingRulesView(zoneId: zoneId)
                )
                ZoneNavRow(
                    title: "IP Access Rules",
                    subtitle: "Allow or block by IP, ASN, country",
                    icon: "network.badge.shield.half.filled",
                    color: .blue,
                    destination: IPAccessRulesView(zoneId: zoneId)
                )
            }

            Section(header: Text("Settings")) {
                ZoneNavRow(
                    title: "Settings",
                    subtitle: "Security level, Bot Fight Mode",
                    icon: "gear.badge.checkmark",
                    color: .gray,
                    destination: SecuritySettingsView(zoneId: zoneId)
                )
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
    }
}
