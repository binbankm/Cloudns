import SwiftUI

// MARK: - PagesAnalyticsInsightsView

struct PagesAnalyticsInsightsView: View {
    // MARK: - Properties
    let totalRequests: Int
    let totalSubrequests: Int
    let totalErrors: Int
    let deploymentSuccessRate: Double
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Pages Edge & Pipeline Summary", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.purple)
            
            HStack {
                Text("Subrequest Ratio")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                let ratio = totalRequests > 0 ? Double(totalSubrequests) / Double(totalRequests) : 0
                Text(String(format: "%.1f subrequests / req", ratio))
                    .font(.caption.weight(.semibold).monospacedDigit())
            }
            
            Divider()
            
            HStack {
                Text("Edge Functions Status")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(totalErrors == 0 ? "Fully Operational" : "\(totalErrors) Invocations Failed")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(totalErrors == 0 ? .green : .orange)
            }
            
            Divider()
            
            HStack {
                Text("Deployment Pipeline")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                (Text(verbatim: String(format: "%.1f%% ", deploymentSuccessRate)) + Text("Success Rate"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
