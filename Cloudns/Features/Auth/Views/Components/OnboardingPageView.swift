import SwiftUI

// MARK: - OnboardingPageView (Luminous Glassmorphism)

struct OnboardingPageView: View {
    // MARK: - Properties
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let color: Color
    let badgeText: LocalizedStringKey
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: CloudnsSpacing.mdLarge)
            
            // 1. Multi-layer Glowing Emblem Card
            ZStack {
                // Outer Ambient Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.35), color.opacity(0.0)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 110
                        )
                    )
                    .frame(width: 220, height: 220)
                    .blur(radius: 20)
                
                // Outer Glass Ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.6), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 156, height: 156)
                
                // Frosted Glass Core Base
                Circle()
                    .fill(CloudnsColor.secondaryGroupedBackground.opacity(0.85))
                    .frame(width: 140, height: 140)
                    .cloudnsShadow(.brand(color: color, radius: 14, y: 6))
                
                // Glowing Icon
                Image(systemName: icon)
                    .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                    .imageScale(.large)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cloudnsShadow(.brand(color: color, radius: 8, y: 3))
                    .accessibilityHidden(true)
            }
            .frame(height: 230)
            
            Spacer(minLength: CloudnsSpacing.lg)
            
            // 2. Feature Badge
            Text(badgeText)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)
                .padding(.horizontal, CloudnsSpacing.smMd)
                .padding(.vertical, CloudnsSpacing.xs)
                .background(color.opacity(0.12))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
                .padding(.bottom, CloudnsSpacing.mdSmall)
            
            // 3. Title Text
            Text(title)
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, CloudnsSpacing.lg)
                .padding(.bottom, CloudnsSpacing.smMd)
                .minimumScaleFactor(0.85)
            
            // 4. Description Subtitle
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, CloudnsSpacing.xl)
            
            Spacer(minLength: 40)
        }
    }
}
