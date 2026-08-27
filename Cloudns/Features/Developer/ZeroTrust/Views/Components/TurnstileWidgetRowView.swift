import SwiftUI

// MARK: - TurnstileWidgetRowView

struct TurnstileWidgetRowView: View {
    // MARK: - Properties
    let widget: TurnstileWidget
    
    // MARK: - Body
    var body: some View {
        HStack(alignment: .center, spacing: CloudnsSpacing.mdMedium) {
            Image(systemName: "checkmark.shield.fill")
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: CloudnsSize.controlHeightSmall, height: CloudnsSize.controlHeightSmall)
                .background(Color.blue.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: CloudnsSpacing.sm) {
                    Text(widget.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    if let mode = widget.mode {
                        CloudnsBadge(.custom(color: .blue, text: mode.capitalized), isCompact: true)
                    }
                }
                
                Text(widget.sitekey)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, CloudnsSpacing.xs)
        .contextMenu {
            Button {
                UIPasteboard.general.string = widget.sitekey
                HapticManager.impact(.light)
                CloudnsToastManager.shared.showCopied("Sitekey copied")
            } label: {
                Label("Copy Sitekey", systemImage: "doc.on.doc")
            }
        }
    }
}
