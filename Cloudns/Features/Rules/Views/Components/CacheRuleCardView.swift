import SwiftUI

// MARK: - CacheRuleCardView

struct CacheRuleCardView: View {
    // MARK: - Properties
    let rule: WAFRule
    let onToggle: () -> Void
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
            HStack {
                Text(rule.description ?? "Unnamed Rule")
                    .font(.body)
                Spacer()
                Toggle(isOn: Binding(
                    get: { rule.enabled },
                    set: { _ in onToggle() }
                )) { }
                .labelsHidden()
            }
            
            Text(rule.expression)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .padding(CloudnsSpacing.sm)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.xs))
                .lineLimit(2)
            
            if let cache = rule.action_parameters?.cache {
                CloudnsBadge(cache ? .active("Eligible for cache") : .error("Bypass cache"), isCompact: true)
            }
        }
        .padding(.vertical, CloudnsSpacing.xs)
    }
}
