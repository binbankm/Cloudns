import SwiftUI

// MARK: - DNSSECDetailRowView

struct DNSSECDetailRowView: View {
    // MARK: - Properties
    let title: String
    let value: String?
    var isLast: Bool = false
    
    // MARK: - Body
    var body: some View {
        if let validValue = value, !validValue.isEmpty {
            HStack(alignment: .center, spacing: CloudnsSpacing.mdSmall) {
                VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                    Text(LocalizedStringKey(title))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(validValue)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, CloudnsSpacing.xs)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = validValue
                    HapticManager.notification(.success)
                    let localizedTitle = NSLocalizedString(title, comment: "")
                    let copyFormat = NSLocalizedString("%@ copied", comment: "")
                    CloudnsToastManager.shared.showCopied(String(format: copyFormat, localizedTitle))
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(.blue)
                }
                .accessibilityLabel("Copy \(title)")
            }
        }
    }
}
