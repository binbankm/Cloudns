import SwiftUI

struct AppIconPickerView: View {
    @StateObject private var iconManager = AppIconManager.shared
    
    var body: some View {
        List {
            Section {
                ForEach(AppIconOption.allCases) { option in
                    Button {
                        HIGFeedback.impact(.medium)
                        Task {
                            await iconManager.selectIcon(option)
                        }
                    } label: {
                        HStack(spacing: HIGTokens.Spacing.lg) {
                            // Icon Preview Squircle
                            ZStack {
                                Image(option.previewImageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous)
                                            .stroke(Color.primary.opacity(0.12), lineWidth: HIGTokens.Elevation.hairlineStroke)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
                                HStack(spacing: HIGTokens.Spacing.sm) {
                                    Text(option.displayName)
                                        .font(HIGTypography.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    
                                    if iconManager.currentIcon == option {
                                        HIGBadge(.active("Active"), isCompact: true)
                                    }
                                }
                                
                                Text(option.subtitle)
                                    .font(HIGTypography.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            if iconManager.currentIcon == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(HIGTypography.title3)
                                    .foregroundStyle(Color.higAccent)
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(.vertical, HIGTokens.Spacing.xs)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.higPressable)
                }
            } header: {
                Text("Select Home Screen Icon")
            } footer: {
                Text("Changes the icon displayed on your home screen and in notifications.")
                    .font(HIGTypography.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            iconManager.syncCurrentIcon()
        }
    }
}

#Preview {
    NavigationStack {
        AppIconPickerView()
    }
}
