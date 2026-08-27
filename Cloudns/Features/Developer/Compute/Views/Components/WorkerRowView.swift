import SwiftUI

// MARK: - WorkerRowView

struct WorkerRowView: View {
    // MARK: - Properties
    let worker: WorkerScript
    
    // MARK: - Body
    var body: some View {
        HStack(alignment: .center, spacing: CloudnsSpacing.mdMedium) {
            ZStack {
                Circle()
                    .fill(CloudnsColor.warningMuted)
                    .frame(width: CloudnsSize.controlHeightSmall, height: CloudnsSize.controlHeightSmall)
                Image(systemName: "bolt.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(CloudnsColor.brandAccent)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(worker.id)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                HStack(spacing: CloudnsSpacing.sm) {
                    if let mod = worker.modifiedOn {
                        Text("Modified: \(DateFormatters.formatISO8601ToDisplay(mod, style: DateFormatters.dateOnly))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let routes = worker.routes, !routes.isEmpty {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text("\(routes.count) routes")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if let usage = worker.usageModel {
                CloudnsBadge(.custom(color: .secondary, text: usage.capitalized), isCompact: true)
            }
        }
        .padding(.vertical, CloudnsSpacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Worker \(worker.id), usage model \(worker.usageModel ?? "standard")")
    }
}
