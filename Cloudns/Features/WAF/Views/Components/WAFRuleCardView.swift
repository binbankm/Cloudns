import SwiftUI

// MARK: - WAFRuleCardView

struct WAFRuleCardView: View {
    // MARK: - Properties
    let rule: WAFRule
    let onToggle: () -> Void
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            HStack {
                Text(rule.description ?? "Untitled Rule")
                    .font(.body)
                    .lineLimit(2)
                
                Spacer()
                
                Toggle(isOn: Binding(
                    get: { rule.enabled },
                    set: { _ in onToggle() }
                )) { }
                .labelsHidden()
            }
            
            HStack {
                CloudnsBadge(.custom(color: colorForAction(rule.action), text: actionDisplayName(rule.action)), isCompact: true)
                
                Spacer()
                
                CloudnsBadge(rule.enabled ? .active("Active") : .custom(color: .secondary, text: "Disabled"), isCompact: true)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                Text("Expression")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(rule.expression)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.primary)
                    .padding(CloudnsSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CloudnsColor.tertiaryGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, CloudnsSpacing.sm)
    }
    
    // MARK: - Actions
    private func actionDisplayName(_ action: String) -> String {
        switch action {
        case "block": return "BLOCK"
        case "challenge": return "LEGACY CAPTCHA"
        case "js_challenge": return "JS CHALLENGE"
        case "managed_challenge": return "MANAGED CHALLENGE"
        case "log": return "LOG"
        case "skip": return "SKIP"
        default: return action.uppercased()
        }
    }
    
    private func colorForAction(_ action: String) -> Color {
        switch action {
        case "block": return .red
        case "challenge", "js_challenge", "managed_challenge": return .orange
        case "log": return .blue
        case "skip": return .green
        default: return .gray
        }
    }
}
