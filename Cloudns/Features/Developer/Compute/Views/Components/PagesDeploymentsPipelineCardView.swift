import SwiftUI

// MARK: - PagesDeploymentsPipelineCardView

struct PagesDeploymentsPipelineCardView: View {
    // MARK: - Properties
    let productionDeploymentsCount: Int
    let previewDeploymentsCount: Int
    let totalDeploymentsCount: Int
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.subheadline)
                    .foregroundStyle(.purple)
                Text("Deployments Pipeline")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("Branch Breakdown")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 16) {
                // Production Bar
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Circle().fill(Color.purple).frame(width: 8, height: 8)
                        Text("Production")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(productionDeploymentsCount)")
                            .font(.headline.monospacedDigit())
                    }
                    ProgressView(
                        value: Double(productionDeploymentsCount),
                        total: max(1, Double(totalDeploymentsCount))
                    )
                    .tint(.purple)
                }
                .padding(12)
                .background(CloudnsColor.tertiaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.smMd))
                
                // Preview Bar
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Circle().fill(Color.blue).frame(width: 8, height: 8)
                        Text("Preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(previewDeploymentsCount)")
                            .font(.headline.monospacedDigit())
                    }
                    ProgressView(
                        value: Double(previewDeploymentsCount),
                        total: max(1, Double(totalDeploymentsCount))
                    )
                    .tint(.blue)
                }
                .padding(12)
                .background(CloudnsColor.tertiaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.smMd))
            }
        }
        .padding(16)
        .background(CloudnsColor.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.lg))
    }
}
