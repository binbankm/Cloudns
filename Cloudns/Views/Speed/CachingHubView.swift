import SwiftUI

struct CachingHubView: View {
    let zoneId: String

    var body: some View {
        List {
            Section {
                ZoneNavRow(
                    title: "Configuration",
                    subtitle: "Cache level, browser TTL, purge",
                    icon: "slider.horizontal.3",
                    color: .cyan,
                    destination: CachingView(zoneId: zoneId)
                )
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Caching")
        .navigationBarTitleDisplayMode(.inline)
    }
}
