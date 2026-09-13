import SwiftUI

// MARK: - Theme Color Picker View (Apple HIG)

struct ThemeColorPickerView: View {
    @ObservedObject private var themeManager = ThemeManager.shared

    private let columns = [
        GridItem(.adaptive(minimum: 72, maximum: 100), spacing: 16)
    ]

    private var presetThemes: [AppThemeColor] {
        AppThemeColor.allCases.filter { $0 != .custom }
    }

    private var customColorBinding: Binding<Color> {
        Binding(
            get: { themeManager.customColor },
            set: { newColor in
                HapticManager.selection()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    themeManager.setCustomColor(newColor)
                }
            }
        )
    }

    var body: some View {
        Form {
            themeGridSection
        }
        .navigationTitle("Theme Color")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 1. Theme Grid Section

    private var themeGridSection: some View {
        Section {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(presetThemes) { theme in
                    themeItem(for: theme)
                }
                customColorWheelItem
            }
            .padding(.vertical, 8)
        } header: {
            Text("Accent Color")
        } footer: {
            Text("Controls the global accent color across navigation bars, tabs, toggles, buttons, and interactive controls.")
        }
    }

    // MARK: - Theme Item Button

    @ViewBuilder
    private func themeItem(for theme: AppThemeColor) -> some View {
        let isSelected = themeManager.currentColor == theme
        let themeColor = theme.presetColor

        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(themeColor)
                    .frame(width: 48, height: 48)
                    .shadow(color: themeColor.opacity(isSelected ? 0.45 : 0.2), radius: isSelected ? 6 : 3, x: 0, y: 2)
                    .overlay(
                        Circle()
                            .strokeBorder(isSelected ? Color.primary.opacity(0.6) : Color.clear, lineWidth: 2.5)
                    )

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 2)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(isSelected ? 1.06 : 1.0)

            Text(theme.displayName)
                .font(.caption2.weight(isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 4)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticManager.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                themeManager.setThemeColor(theme)
            }
            ToastManager.shared.showSuccess(LocalizedStringKey("Theme Color Updated"), icon: "paintpalette.fill")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(theme.displayName)
        .accessibilityHint(isSelected ? "Currently selected theme color" : "Tap to set as theme color")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : [.isButton])
    }

    // MARK: - Custom Color Wheel Disc

    private var customColorWheelItem: some View {
        let isCustom = themeManager.currentColor == .custom
        let customVal = themeManager.customColor

        return VStack(spacing: 8) {
            ZStack {
                if isCustom {
                    Circle()
                        .fill(customVal)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    AngularGradient(
                                        colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red],
                                        center: .center
                                    ),
                                    lineWidth: 3
                                )
                        )
                        .shadow(color: customVal.opacity(0.45), radius: 6, x: 0, y: 2)

                    Image(systemName: "checkmark")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 2)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red],
                                center: .center
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.85), lineWidth: 1.5)
                        )
                        .overlay(
                            Image(systemName: "paintpalette.fill")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.4), radius: 2)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                }

                ColorPicker("Custom Color", selection: customColorBinding, supportsOpacity: false)
                    .labelsHidden()
                    .opacity(0.02)
                    .frame(width: 48, height: 48)
            }
            .scaleEffect(isCustom ? 1.06 : 1.0)
            .frame(width: 48, height: 48)

            Text("Custom")
                .font(.caption2.weight(isCustom ? .bold : .medium))
                .foregroundStyle(isCustom ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .onTapGesture {
                    if themeManager.currentColor != .custom {
                        HapticManager.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            themeManager.setThemeColor(.custom)
                        }
                        ToastManager.shared.showSuccess(LocalizedStringKey("Theme Color Updated"), icon: "paintpalette.fill")
                    }
                }
        }
        .padding(.vertical, 4)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityLabel("Custom Color")
        .accessibilityHint("Tap to open color wheel picker")
    }
}
