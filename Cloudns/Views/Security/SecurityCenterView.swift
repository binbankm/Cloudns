import SwiftUI

struct SecurityCenterView: View {
    let zoneId: String
    let zoneName: String
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(.red)
                        .padding(.top, 10)
                        .accessibilityHidden(true)
                    
                    Text("Security Center")
                        .font(.title2)
                    
                    Text("Comprehensive threat defense and encryption management for \(zoneName).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            
            Section {
                NavigationLink(destination: SecuritySettingsView(zoneId: zoneId)) {
                    FeatureRowContent(title: "Basic Security", icon: "shield.fill", color: .red)
                }
                
                NavigationLink(destination: SSLSettingsView(zoneId: zoneId)) {
                    FeatureRowContent(title: "SSL / TLS", icon: "lock.fill", color: .orange)
                }
                
                NavigationLink(destination: IPAccessRulesView(zoneId: zoneId)) {
                    FeatureRowContent(title: "IP Access Rules", icon: "network.badge.shield.half.filled", color: .blue)
                }
                
                NavigationLink(destination: ScrapeShieldView(zoneId: zoneId)) {
                    FeatureRowContent(title: "Scrape Shield", icon: "eye.slash.fill", color: .purple)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Security Center")
        .navigationBarTitleDisplayMode(.inline)
    }
}
