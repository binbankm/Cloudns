import SwiftUI

// MARK: - TransformRuleCardView

struct TransformRuleCardView: View {
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
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .padding(6)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .lineLimit(2)
            
            if let uri = rule.action_parameters?.uri {
                if let path = uri.path?.value {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .foregroundStyle(.blue)
                            .font(.caption2)
                            .accessibilityHidden(true)
                        Text("Rewrite Path -> \(path)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if let query = uri.query?.value {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.indigo)
                            .font(.caption2)
                            .accessibilityHidden(true)
                        Text("Rewrite Query -> \(query)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if let headers = rule.action_parameters?.headers {
                ForEach(Array(headers.keys), id: \.self) { headerKey in
                    if let item = headers[headerKey] {
                        HStack(spacing: 4) {
                            Image(systemName: item.operation == "remove" ? "minus.circle.fill" : "plus.circle.fill")
                                .foregroundStyle(item.operation == "remove" ? .red : .green)
                                .font(.caption2)
                                .accessibilityHidden(true)
                            Text("\(item.operation.capitalized) '\(headerKey)': \(item.value ?? "(removed)")")
                                .font(.caption)
                                .foregroundStyle(item.operation == "remove" ? .red : .primary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
