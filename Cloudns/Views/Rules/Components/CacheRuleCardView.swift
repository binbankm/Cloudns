import SwiftUI

// MARK: - CacheRuleCardView

struct CacheRuleCardView: View {
    let rule: WAFRule
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rule.description ?? "Unnamed Rule")
                    .font(.body)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { rule.enabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }
            
            Text(rule.expression)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .padding(6)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .lineLimit(2)
            
            if let cache = rule.action_parameters?.cache {
                CloudnsBadge(cache ? .active("Eligible for cache") : .error("Bypass cache"), isCompact: true)
            }
        }
        .padding(.vertical, 4)
    }
}
