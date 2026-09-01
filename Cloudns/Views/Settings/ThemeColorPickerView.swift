import SwiftUI

// MARK: - Theme Color Picker View (Apple HIG)

struct ThemeColorPickerView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    private let columns = [
        GridItem(.adaptive(minimum: 72, maximum: 100), spacing: 16)
    ]
    
    var body: some View {
        Form {
            Section {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(AppThemeColor.allCases) { theme in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                themeManager.setThemeColor(theme)
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
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(theme.displayName)
                        .accessibilityHint(themeManager.currentColor == theme ? "Currently selected theme color" : "Double tap to set as theme color")
                    }
                }
                .padding(.vertical, 10)
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
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Theme Color")
        .navigationBarTitleDisplayMode(.inline)
    }
}
