import SwiftUI

// MARK: - IPAccessRuleRowView

struct IPAccessRuleRowView: View {
    let rule: IPAccessRule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rule.configuration.value)
                    .font(.body.monospacedDigit())
                
                Spacer()
                
                CloudnsBadge(.custom(color: colorForMode(rule.mode), text: rule.mode.uppercased()), isCompact: true)
            }
            
            HStack {
                Text(rule.configuration.target.uppercased().replacingOccurrences(of: "_", with: " "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let notes = rule.notes, !notes.isEmpty {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorForMode(_ mode: String) -> Color {
        switch mode {
        case "block": return .red
        case "challenge", "js_challenge", "managed_challenge": return .orange
        case "whitelist": return .green
        default: return .blue
        }
    }
}
