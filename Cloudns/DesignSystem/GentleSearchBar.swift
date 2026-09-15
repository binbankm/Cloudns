import SwiftUI

// MARK: - Gentle Search Bar Component

/// An ultra-gentle search bar styled with rounded squircle container,
/// amber halo on focus, clear button, and smooth spring cancel animation.
public struct GentleSearchBar: View {
    @Binding private var text: String
    private let placeholder: String
    private let onCommit: (() -> Void)?

    @FocusState private var isFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        text: Binding<String>,
        placeholder: String = "Search domains or records",
        onCommit: (() -> Void)? = nil
    ) {
        _text = text
        self.placeholder = placeholder
        self.onCommit = onCommit
    }

    public var body: some View {
        HStack(spacing: GentleSpacing.sm) {
            // Search Input Pill
            HStack(spacing: GentleSpacing.xs) {
                Image(systemName: "magnifyingglass")
                    .font(GentleTypography.subheadline)
                    .foregroundStyle(isFocused ? GentleColor.accent : GentleColor.textSecondary)
                    .animation(reduceMotion ? nil : GentleAnimation.spring, value: isFocused)

                TextField(
                    LocalizedStringKey(placeholder),
                    text: $text
                )
                .font(GentleTypography.body)
                .foregroundStyle(GentleColor.textPrimary)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit {
                    onCommit?()
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

                if !text.isEmpty {
                    Button {
                        GentleHaptics.selection()
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(GentleTypography.callout)
                            .foregroundStyle(GentleColor.textTertiary)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Clear search text"))
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, GentleSpacing.sm)
            .frame(height: 42)
            .background(GentleColor.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: GentleCornerRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: GentleCornerRadius.lg, style: .continuous)
                    .stroke(
                        isFocused ? GentleColor.accent.opacity(0.35) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: isFocused ? GentleColor.accent.opacity(0.08) : Color.black.opacity(0.03),
                radius: isFocused ? 8 : 4,
                x: 0,
                y: 2
            )

            // Cancel Button (Animated Slide In)
            if isFocused || !text.isEmpty {
                Button {
                    GentleHaptics.light()
                    withAnimation(reduceMotion ? nil : GentleAnimation.spring) {
                        text = ""
                        isFocused = false
                    }
                } label: {
                    Text("Cancel")
                        .font(GentleTypography.bodyMedium)
                        .foregroundStyle(GentleColor.accent)
                }
                .transition(reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : GentleAnimation.spring, value: isFocused || !text.isEmpty)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preview

#if DEBUG
    struct GentleSearchBar_Previews: PreviewProvider {
        static var previews: some View {
            StatefulPreviewWrapper("") { text in
                VStack(spacing: 20) {
                    GentleSearchBar(text: text)
                    Text("Query: \(text.wrappedValue)")
                        .font(GentleTypography.footnote)
                        .foregroundStyle(GentleColor.textSecondary)
                    Spacer()
                }
                .padding()
                .background(GentleColor.background)
            }
        }

        private struct StatefulPreviewWrapper<Value, Content: View>: View {
            @State private var value: Value
            private let content: (Binding<Value>) -> Content

            init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
                _value = State(initialValue: initialValue)
                self.content = content
            }

            var body: some View {
                content($value)
            }
        }
    }
#endif
