import SwiftUI

// MARK: - Theme Color Picker View (Apple HIG)

struct ThemeColorPickerView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var customColor: Color = .orange
    
    private let columns = [
        GridItem(.adaptive(minimum: 72, maximum: 100), spacing: 16)
    ]
    
    private var presetThemes: [AppThemeColor] {
        AppThemeColor.allCases.filter { $0 != .custom }
    }
    
    var body: some View {
        Form {
            Section {
                LazyVGrid(columns: columns, spacing: 16) {
                    // 1. Preset Classic Themes (9 Colors)
                    ForEach(presetThemes) { theme in
                        Button {
                            HapticManager.impact(.light)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                themeManager.setThemeColor(theme)
                                ToastManager.shared.showSuccess("Theme Color Updated", icon: "paintpalette.fill")
                            }
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(theme.color)
                                        .frame(width: 48, height: 48)
                                        .shadow(color: theme.color.opacity(0.3), radius: 4, x: 0, y: 2)
                                    
                                    if themeManager.currentColor == theme {
                                        Image(systemName: "checkmark")
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(.white)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                
                                Text(theme.displayName)
                                    .font(.caption2.weight(themeManager.currentColor == theme ? .bold : .medium))
                                    .foregroundStyle(themeManager.currentColor == theme ? .primary : .secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(.vertical, 4)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(theme.displayName)
                        .accessibilityHint(themeManager.currentColor == theme ? "Currently selected theme color" : "Double tap to set as theme color")
                    }
                    
                    // 2. Custom Color Spectrum Wheel Disc (10th Item)
                    customColorWheelItem
                }
                .padding(.vertical, 8)
            } header: {
                Text("Accent Color")
            } footer: {
                Text("Controls the global accent color across navigation bars, tabs, toggles, buttons, and interactive controls.")
            }
            
            Section("Preview") {
                HStack(spacing: 12) {
                    Button("Solid Button") {}
                        .buttonStyle(.borderedProminent)
                        .tint(themeManager.currentColor.color)
                    
                    Button("Bordered") {}
                        .buttonStyle(.bordered)
                        .tint(themeManager.currentColor.color)
                    
                    Toggle(isOn: .constant(true)) {
                        EmptyView()
                    }
                    .tint(themeManager.currentColor.color)
                    .labelsHidden()
                    
                    if themeManager.currentColor == .custom, let hex = themeManager.customColor.toHex() {
                        Spacer()
                        Text(hex)
                            .font(.caption.monospaced().weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(uiColor: .tertiarySystemFill))
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Theme Color")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            customColor = themeManager.customColor
        }
        .onChange(of: customColor) { newColor in
            HapticManager.impact(.light)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                themeManager.setCustomColor(newColor)
            }
        }
    }
    
    // MARK: - Custom Color Wheel Disc
    private var customColorWheelItem: some View {
        VStack(spacing: 8) {
            ZStack {
                if themeManager.currentColor == .custom {
                    Circle()
                        .fill(themeManager.customColor)
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
                        .shadow(color: themeManager.customColor.opacity(0.35), radius: 4, x: 0, y: 2)
                    
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
                
                // Native ColorPicker overlay covering the entire touch area
                ColorPicker("Custom Color", selection: $customColor, supportsOpacity: false)
                    .labelsHidden()
                    .opacity(0.015)
            }
            .frame(width: 48, height: 48)
            
            Text("Custom")
                .font(.caption2.weight(themeManager.currentColor == .custom ? .bold : .medium))
                .foregroundStyle(themeManager.currentColor == .custom ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 4)
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel("Custom Color")
        .accessibilityHint("Double tap to open color wheel picker")
    }
}
