import SwiftUI

struct PerformanceCenterView: View {
    let zoneId: String
    let zoneName: String
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(.orange)
                        .padding(.top, 10)
                        .accessibilityHidden(true)
                    
                    Text("Performance & Speed")
                        .font(.title2)
                    
                    Text("Supercharge \(zoneName) with CDN caching and web optimization technologies.")
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
                NavigationLink(destination: CachingView(zoneId: zoneId)) {
                    FeatureRowContent(title: "Caching Options", icon: "memorychip", color: .purple)
                }
                
                NavigationLink(destination: SpeedSettingsView(zoneId: zoneId)) {
                    FeatureRowContent(title: "Speed Optimization", icon: "hare.fill", color: .orange)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Performance")
        .navigationBarTitleDisplayMode(.inline)
    }
}
