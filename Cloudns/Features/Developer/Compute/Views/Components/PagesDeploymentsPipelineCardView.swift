import SwiftUI

// MARK: - PagesDeploymentsPipelineCardView

struct PagesDeploymentsPipelineCardView: View {
    // MARK: - Properties
    let productionDeploymentsCount: Int
    let previewDeploymentsCount: Int
    let totalDeploymentsCount: Int
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
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
            
            HStack(spacing: CloudnsSpacing.md) {
                // Production Bar
                VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
                    HStack {
                        Circle().fill(Color.purple).frame(width: CloudnsSize.iconMini, height: CloudnsSize.iconMini)
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
                .padding(CloudnsSpacing.mdSmall)
                .background(CloudnsColor.tertiaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.mdLg))
                
                // Preview Bar
                VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
                    HStack {
                        Circle().fill(Color.blue).frame(width: CloudnsSize.iconMini, height: CloudnsSize.iconMini)
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
                .padding(CloudnsSpacing.mdSmall)
                .background(CloudnsColor.tertiaryGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.mdLg))
            }
        }
        .padding(CloudnsSpacing.md)
        .background(CloudnsColor.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.lg))
    }
}
