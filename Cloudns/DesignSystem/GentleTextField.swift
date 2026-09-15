import SwiftUI

// MARK: - Gentle Text Field Component

public struct GentleTextField: View {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    public let placeholder: String
    @Binding public var text: String
    public var leadingIcon: String?
    public var isSecure: Bool
    public var isMonospaced: Bool
    public var keyboardType: UIKeyboardType
    public var autocapitalization: TextInputAutocapitalization?
    public var disableAutocorrection: Bool
    public var onCommit: (() -> Void)?

    @FocusState private var isFocused: Bool
    @State private var isSecureRevealed: Bool = false

    public init(
        _ placeholder: String,
        text: Binding<String>,
        leadingIcon: String? = nil,
        isSecure: Bool = false,
        isMonospaced: Bool = false,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization? = nil,
        disableAutocorrection: Bool = false,
        onCommit: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        _text = text
        self.leadingIcon = leadingIcon
        self.isSecure = isSecure
        self.isMonospaced = isMonospaced
        self.keyboardType = keyboardType
        self.autocapitalization = autocapitalization ?? (isSecure || isMonospaced ? .never : nil)
        self.disableAutocorrection = disableAutocorrection || isSecure || isMonospaced
        self.onCommit = onCommit
    }

    private var currentFont: Font {
        if isMonospaced {
            return GentleTypography.codeValue
        }
        return GentleTypography.body
    }

    private var borderStrokeColor: Color {
        if isFocused {
            return GentleColor.accent.opacity(colorSchemeContrast == .increased ? 0.9 : 0.6)
        }
        return colorSchemeContrast == .increased
            ? GentleColor.textSecondary.opacity(0.35)
            : GentleColor.textSecondary.opacity(0.16)
    }

    public var body: some View {
        HStack(spacing: GentleSpacing.sm) {
            if let leadingIcon {
                Image(systemName: leadingIcon)
                    .font(GentleTypography.bodyMedium)
                    .foregroundStyle(isFocused ? GentleColor.accent : GentleColor.textSecondary)
                    .frame(width: 22)
                    .accessibilityHidden(true)
            }

            Group {
                if isSecure, !isSecureRevealed {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(currentFont)
            .foregroundStyle(GentleColor.textPrimary)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled(disableAutocorrection)
            .focused($isFocused)
            .onSubmit {
                onCommit?()
            }

            if isSecure {
                Button {
                    isSecureRevealed.toggle()
                    GentleHaptics.selection()
                } label: {
                    Image(systemName: isSecureRevealed ? "eye.slash.fill" : "eye.fill")
                        .font(GentleTypography.subheadline)
                        .foregroundStyle(GentleColor.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Hide credential"))
            }

            if !text.isEmpty, isFocused {
                Button {
                    text = ""
                    GentleHaptics.soft()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(GentleTypography.body)
                        .foregroundStyle(GentleColor.textSecondary.opacity(0.7))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Clear input text"))
            }
        }
        .padding(.horizontal, GentleSpacing.md)
        .frame(height: 52)
        .background(GentleColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: GentleCornerRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: GentleCornerRadius.xl, style: .continuous)
                .stroke(borderStrokeColor, lineWidth: isFocused ? 1.5 : 1.0)
        )
        .animation(GentleAnimation.spring, value: isFocused)
    }
}
