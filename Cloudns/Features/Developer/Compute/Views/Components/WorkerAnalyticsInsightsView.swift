import SwiftUI

// MARK: - WorkerAnalyticsInsightsView

struct WorkerAnalyticsInsightsView: View {
    // MARK: - Properties
    let totalRequests: Int
    let totalSubrequests: Int
    let totalErrors: Int
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Worker Performance Summary", systemImage: "sparkles")
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
                Text("Execution Health")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(totalErrors == 0 ? "Fully Operational" : "\(totalErrors) Exceptions Detected")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(totalErrors == 0 ? .green : .orange)
            }
        }
        .padding(14)
        .background(CloudnsColor.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.lg))
    }
}
