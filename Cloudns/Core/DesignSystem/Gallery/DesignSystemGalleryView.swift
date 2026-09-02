import SwiftUI

// MARK: - Apple HIG Design System Interactive Gallery & Style Guide
// Visual verification and debugging canvas for all tokens, components, haptics, and theme switches

#if DEBUG
public struct DesignSystemGalleryView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var sampleText: String = ""
    @State private var sampleToggle: Bool = true
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                // MARK: 1. Dynamic Theming
                Section("Dynamic Accent Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: HIGTokens.Spacing.md) {
                            ForEach(AppThemeColor.allCases) { theme in
                                Button {
                                    themeManager.setThemeColor(theme)
                                } label: {
                                    VStack(spacing: HIGTokens.Spacing.xs) {
                                        ZStack {
                                            Circle()
                                                .fill(theme.color)
                                                .frame(width: 44, height: 44)
                                                .shadow(color: theme.color.opacity(0.35), radius: 6, x: 0, y: 2)
                                            
                                            if themeManager.currentColor == theme {
                                                Image(systemName: "checkmark")
                                                    .font(HIGTypography.headline.weight(.bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        
                                        Text(theme.displayName)
                                            .font(HIGTypography.caption2)
                                            .foregroundStyle(themeManager.currentColor == theme ? .primary : .secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .higTouchTarget()
                            }
                        }
                        .padding(.vertical, HIGTokens.Spacing.xs)
                    }
                }
                
                // MARK: 2. Badges
                Section("Status Badges (Multi-Channel A11y)") {
                    VStack(alignment: .leading, spacing: HIGTokens.Spacing.sm) {
                        HStack {
                            HIGBadge(.proxied)
                            HIGBadge(.dnsOnly)
                            HIGBadge(.active)
                            HIGBadge(.free)
                        }
                        HStack {
                            HIGBadge(.pro)
                            HIGBadge(.enterprise)
                            HIGBadge(.warning("Warning"))
                            HIGBadge(.error("Error"))
                        }
                    }
                    .padding(.vertical, HIGTokens.Spacing.xs)
                }
                
                // MARK: 3. Buttons & Interactions
                Section("Button Styles") {
                    Button("Primary Action Button") {
                        ToastManager.shared.showSuccess("Primary Button Tapped")
                    }
                    .buttonStyle(.higPrimaryAction)
                    
                    Button {
                        ToastManager.shared.showCopied()
                    } label: {
                        HStack {
                            ListRowIcon(icon: "doc.on.doc.fill", color: .blue)
                            Text("Pressable Row Action")
                                .font(HIGTypography.body)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(HIGTypography.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.higPressable)
                }
                
                // MARK: 4. Card Modifier
                Section("Bento Card Style") {
                    VStack(alignment: .leading, spacing: HIGTokens.Spacing.sm) {
                        HStack {
                            ListRowIcon(icon: "globe", color: HIGColors.accent)
                            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                                Text("example.com")
                                    .font(HIGTypography.headline)
                                Text("Active · 12,480 Requests")
                                    .font(HIGTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            HIGBadge(.proxied, isCompact: true)
                        }
                    }
                    .higCardStyle(isElevated: true)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                
                // MARK: 5. Haptics & Feedback
                Section("Haptics & Toasts") {
                    Button("Success Haptic & Toast") {
                        ToastManager.shared.showSuccess("Changes Saved Successfully")
                    }
                    Button("Copied Toast") {
                        ToastManager.shared.showCopied("Domain Copied")
                    }
                    Button("Error Haptic & Toast") {
                        ToastManager.shared.showError("Network Timeout")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Design System")
        }
        .higToast()
    }
}

#Preview {
    DesignSystemGalleryView()
}
#endif
