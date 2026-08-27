import SwiftUI

/// DevTools 历史查询快捷 Chips 胶囊组件
struct QueryHistoryChipsView: View {
    // MARK: - Properties
    let history: [String]
    let onSelect: (String) -> Void
    let onClear: () -> Void
    
    // MARK: - Body
    var body: some View {
        if !history.isEmpty {
            VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                HStack {
                    Label("Recent Queries", systemImage: "clock.arrow.circlepath")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button {
                        HapticManager.impact(.light)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            onClear()
                        }
                    } label: {
                        Text("Clear")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search history")
                }
                .padding(.horizontal, CloudnsSpacing.xxs)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: CloudnsSpacing.sm) {
                        ForEach(history, id: \.self) { item in
                            Button {
                                HapticManager.impact(.light)
                                onSelect(item)
                            } label: {
                                HStack(spacing: CloudnsSpacing.xs) {
                                    Text(item)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, CloudnsSpacing.sm)
                                .padding(.vertical, CloudnsSpacing.xs)
                                .background(CloudnsColor.chipBackground)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Search \(item)")
                        }
                    }
                    .padding(.vertical, CloudnsSpacing.xxs)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}
