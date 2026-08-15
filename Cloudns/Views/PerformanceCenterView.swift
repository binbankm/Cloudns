import SwiftUI

struct PerformanceCenterView: View {
    let zoneId: String
    let zoneName: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Bolt Graphic Header
                VStack(spacing: 12) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(.orange)
                        .padding(.top, 10)
                    
                    Text("Performance & Speed")
                        .font(.title2)
                    
                    Text("Supercharge \(zoneName) with CDN caching and web optimization technologies.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.bottom, 10)
                
                // Menu List
                VStack(spacing: 0) {
                    
                    NavigationLink(destination: CachingView(zoneId: zoneId)) {
                        FeatureRowContent(title: "Caching Options", icon: "memorychip", color: .purple)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider().padding(.leading, 64)
                    
                    NavigationLink(destination: SpeedSettingsView(zoneId: zoneId)) {
                        FeatureRowContent(title: "Speed Optimization", icon: "hare.fill", color: .orange)
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
        .navigationTitle("Performance")
        .navigationBarTitleDisplayMode(.inline)
    }
}
