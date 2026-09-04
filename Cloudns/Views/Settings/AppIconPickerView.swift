import SwiftUI

struct AppIconPickerView: View {
    @StateObject private var iconManager = AppIconManager.shared
    
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
                        HStack(spacing: 16) {
                            // Icon Preview Squircle
                            ZStack {
                                Image(option.previewImageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(option.displayName)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    
                                    if iconManager.currentIcon == option {
                                        Text("Active")
                                            .font(.caption2.weight(.medium))
                                            .foregroundStyle(Color.accentColor)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(Color.accentColor.opacity(0.12)))
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
                                    .foregroundStyle(Color.accentColor)
                                    .accessibilityHidden(true)
                            }
                        }
                        .padding(.vertical, 4)
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
