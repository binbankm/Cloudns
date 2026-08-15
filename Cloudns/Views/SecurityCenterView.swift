import SwiftUI

struct SecurityCenterView: View {
    let zoneId: String
    let zoneName: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Shield Graphic Header
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(.red)
                        .padding(.top, 10)
                    
                    Text("Security Center")
                        .font(.title2)
                    
                    Text("Comprehensive threat defense and encryption management for \(zoneName).")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.bottom, 10)
                
                // Menu List
                VStack(spacing: 0) {
                    
                    NavigationLink(destination: SecuritySettingsView(zoneId: zoneId)) {
                        FeatureRowContent(title: "Basic Security", icon: "shield.fill", color: .red)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider().padding(.leading, 64)
                    
                    NavigationLink(destination: SSLSettingsView(zoneId: zoneId)) {
                        FeatureRowContent(title: "SSL / TLS", icon: "lock.fill", color: .orange)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider().padding(.leading, 64)
                    
                    NavigationLink(destination: IPAccessRulesView(zoneId: zoneId)) {
                        FeatureRowContent(title: "IP Access Rules", icon: "network.badge.shield.half.filled", color: .blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider().padding(.leading, 64)
                    
                    NavigationLink(destination: ScrapeShieldView(zoneId: zoneId)) {
                        FeatureRowContent(title: "Scrape Shield", icon: "eye.slash.fill", color: .purple)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationTitle("Security Center")
        .navigationBarTitleDisplayMode(.inline)
    }
}
