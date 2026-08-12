import SwiftUI

struct ZoneDetailView: View {
    let zone: Zone
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Premium Zone Info Card
                VStack(spacing: 0) {
                    // Header Gradient Area
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(
                            gradient: Gradient(colors: zone.status == "active" ? [Color.green.opacity(0.8), Color.mint.opacity(0.6)] : [Color.orange.opacity(0.8), Color.red.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 90)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(zone.name)
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                
                                HStack(spacing: 6) {
                                    Image(systemName: zone.status == "active" ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    Text(zone.status.capitalized)
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.25))
                                .cornerRadius(6)
                            }
                            
                            Spacer()
                            
                            Text(zone.type.capitalized)
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.25))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                        }
                        .padding(16)
                    }
                    
                    // Body Area
                    if !zone.nameServers.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Cloudflare Nameservers")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: {
                                    UIPasteboard.general.string = zone.nameServers.joined(separator: "\n")
                                    let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
                                }) {
                                    Image(systemName: "doc.on.doc.fill")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(zone.nameServers, id: \.self) { ns in
                                    HStack(spacing: 8) {
                                        Image(systemName: "server.rack")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                        Text(ns)
                                            .font(.subheadline.monospaced())
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .cornerRadius(8)
                        }
                        .padding(16)
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                
                // Super Hubs Menu
                VStack(alignment: .leading, spacing: 16) {
                    Text("Super Hubs")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 0) {
                        NavigationLink(destination: AnalyticsView(zoneId: zone.id, zoneName: zone.name)) {
                            FeatureRowContent(title: "Traffic & Analytics", icon: "chart.xyaxis.line", color: .indigo)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider().padding(.leading, 64)
                        
                        NavigationLink(destination: DNSRecordsView(zoneId: zone.id, zoneName: zone.name)) {
                            FeatureRowContent(title: "DNS Management", icon: "server.rack", color: .blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider().padding(.leading, 64)
                        
                        NavigationLink(destination: SecurityCenterView(zoneId: zone.id, zoneName: zone.name)) {
                            FeatureRowContent(title: "Security Center", icon: "shield.fill", color: .red)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider().padding(.leading, 64)
                        
                        NavigationLink(destination: PerformanceCenterView(zoneId: zone.id, zoneName: zone.name)) {
                            FeatureRowContent(title: "Performance & Speed", icon: "bolt.fill", color: .orange)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider().padding(.leading, 64)
                        
                        NavigationLink(destination: NetworkCenterView(zoneId: zone.id, zoneName: zone.name)) {
                            FeatureRowContent(title: "Network & Routing", icon: "network", color: .purple)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider().padding(.leading, 64)
                        
                        NavigationLink(destination: RulesCenterView(zoneId: zone.id, zoneName: zone.name)) {
                            FeatureRowContent(title: "Rules & Routing", icon: "arrow.triangle.swap", color: .teal)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationTitle(zone.name)
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: dateString)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: dateString)
        }
        
        guard let validDate = date else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        displayFormatter.locale = Locale(identifier: "en_US")
        return displayFormatter.string(from: validDate)
    }
}

struct FeatureRowContent: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                color.opacity(0.15)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(width: 32, height: 32)
            .cornerRadius(8)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(UIColor.tertiaryLabel))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
}
