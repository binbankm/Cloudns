import SwiftUI

// MARK: - WorkerRowView

struct WorkerRowView: View {
    let worker: WorkerScript
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "bolt.fill")
                .font(.body)
                .foregroundStyle(Color.orange)
                .frame(width: 32, height: 32)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(worker.id)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
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
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Worker \(worker.id), usage model \(worker.usageModel ?? "standard")")
    }
}
