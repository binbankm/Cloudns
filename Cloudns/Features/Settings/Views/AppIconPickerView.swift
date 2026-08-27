import SwiftUI

struct AppIconPickerView: View {
    // MARK: - Properties
    @StateObject private var iconManager = AppIconManager.shared
    
    // MARK: - Body
    var body: some View {
        List {
            Section {
                ForEach(AppIconOption.allCases) { option in
                    Button {
                        HapticManager.impact(.medium)
                        Task {
                            await iconManager.selectIcon(option)
                        }
                    } label: {
                        HStack(spacing: CloudnsSpacing.md) {
                            // Icon Preview Squircle
                            ZStack {
                                Image(option.previewImageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: CloudnsSize.avatarLarge, height: CloudnsSize.avatarLarge)
                                    .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md, style: .continuous))
                                    .cloudnsShadow(.card)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CloudnsRadius.md, style: .continuous)
                                            .stroke(CloudnsColor.glassBorder, lineWidth: 1)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                                HStack(spacing: CloudnsSpacing.sm) {
                                    Text(option.displayName)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    
                                    if iconManager.currentIcon == option {
                                        CloudnsBadge(.custom(color: .orange, text: "Active"), isCompact: true)
                                    }
                                }
                                
                                Text(option.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            if iconManager.currentIcon == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(CloudnsColor.brandAccent)
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(.vertical, CloudnsSpacing.xs)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Select Home Screen Icon")
            } footer: {
                Text("Changes the icon displayed on your home screen and in notifications.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            iconManager.syncCurrentIcon()
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AppIconPickerView()
    }
}
