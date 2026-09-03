import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppStorageKey.hasSeenOnboarding) private var hasSeenOnboarding = false
    @State private var currentPage = 0
    
    private let totalPages = 4
    
    private var currentColor: Color {
        switch currentPage {
        case 0: return .blue
        case 1: return .green
        case 2: return .orange
        default: return .purple
        }
    }
    
    private func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            hasSeenOnboarding = true
        }
        dismiss()
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            GeometryReader { proxy in
                let w = proxy.size.width
                
                ZStack {
                    Circle()
                        .fill(currentColor.opacity(0.18))
                        .frame(width: w * 0.9, height: w * 0.9)
                        .blur(radius: 65)
                        .offset(x: -w * 0.25, y: -w * 0.3)
                    
                    Circle()
                        .fill(currentColor.opacity(0.12))
                        .frame(width: w * 0.8, height: w * 0.8)
                        .blur(radius: 70)
                        .offset(x: w * 0.3, y: w * 0.6)
                }
                .animation(.easeInOut(duration: 0.5), value: currentPage)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar: Brand & Skip Action
                HStack {
                    HStack(spacing: HIGTokens.Spacing.xs) {
                        Image(systemName: "cloud.fill")
                            .font(HIGTypography.subheadline.weight(.bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("Cloudns")
                            .font(HIGTypography.headline.weight(.bold))
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    Button("Skip") {
                        HIGFeedback.impact(.light)
                        completeOnboarding()
                    }
                    .font(HIGTypography.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, HIGTokens.Spacing.md)
                    .padding(.vertical, HIGTokens.Spacing.xs + 2)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
                    .buttonStyle(.higPressable)
                    .higTouchTarget()
                }
                .padding(.horizontal, HIGTokens.Spacing.xxl)
                .padding(.top, HIGTokens.Spacing.md)
                
                // Tab Pages
                TabView(selection: $currentPage) {
                    OnboardingPageView(
                        icon: "globe.asia.australia.fill",
                        title: "Global Edge Network",
                        description: "Manage all Cloudflare DNS records, edge routing, and instant cache purging with zero latency.",
                        color: .blue,
                        badgeText: "DNS & Edge Fleet"
                    )
                    .tag(0)
                    
                    OnboardingPageView(
                        icon: "shield.lefthalf.filled",
                        title: "Enterprise Shield",
                        description: "Instantly toggle Under Attack Mode, orchestrate WAF firewall rules, and fend off DDoS threats.",
                        color: .green,
                        badgeText: "Security & WAF"
                    )
                    .tag(1)
                    
                    OnboardingPageView(
                        icon: "bolt.fill",
                        title: "Serverless Execution",
                        description: "Monitor Workers, Pages builds, and KV/D1 databases with live execution metrics and latency tracing.",
                        color: .orange,
                        badgeText: "Compute & Storage"
                    )
                    .tag(2)
                    
                    OnboardingPageView(
                        icon: "faceid",
                        title: "Biometric Privacy",
                        description: "Your API credentials stay isolated on your device with Apple Keychain hardware-level protection.",
                        color: .purple,
                        badgeText: "Face ID & Local Keys"
                    )
                    .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: currentPage) { _ in
                    HIGFeedback.selection()
                }
                
                // Bottom Controls
                VStack(spacing: HIGTokens.Spacing.xl) {
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? currentColor : Color.secondary.opacity(0.25))
                                .frame(width: currentPage == index ? 24 : 7, height: 7)
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    .padding(.vertical, HIGTokens.Spacing.xs)
                    
                    Button(action: {
                        if currentPage < totalPages - 1 {
                            HIGFeedback.impact(.light)
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                currentPage += 1
                            }
                        } else {
                            HIGFeedback.impact(.medium)
                            completeOnboarding()
                        }
                    }) {
                        HStack(spacing: HIGTokens.Spacing.sm) {
                            Text(currentPage == totalPages - 1 ? "Get Started" : "Continue")
                                .font(HIGTypography.body.weight(.semibold))
                            
                            Image(systemName: currentPage == totalPages - 1 ? "checkmark" : "arrow.right")
                                .font(HIGTypography.subheadline.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [currentColor, currentColor.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.lg, style: .continuous))
                        .shadow(color: currentColor.opacity(0.35), radius: 12, x: 0, y: 5)
                    }
                    .buttonStyle(.higPressable)
                    .padding(.horizontal, HIGTokens.Spacing.xxl)
                }
                .padding(.bottom, HIGTokens.Spacing.xxl)
            }
        }
    }
}

// MARK: - OnboardingPageView (Inlined & Cohesive)

struct OnboardingPageView: View {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let color: Color
    let badgeText: LocalizedStringKey
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)
            
            ZStack {
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
                
                Circle()
                    .fill(Color.higCardBackground.opacity(0.85))
                    .frame(width: 140, height: 140)
                    .shadow(color: color.opacity(0.25), radius: 16, x: 0, y: 8)
                
                Image(systemName: icon)
                    .font(HIGTypography.largeTitle.weight(.semibold))
                    .imageScale(.large)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: color.opacity(0.45), radius: 8, x: 0, y: 3)
                    .accessibilityHidden(true)
            }
            .frame(height: 230)
            
            Spacer(minLength: HIGTokens.Spacing.xxl)
            
            Text(badgeText)
                .font(HIGTypography.caption2.weight(.bold))
                .foregroundStyle(color)
                .padding(.horizontal, HIGTokens.Spacing.md)
                .padding(.vertical, HIGTokens.Spacing.xs)
                .background(color.opacity(0.12))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
                .padding(.bottom, HIGTokens.Spacing.md)
            
            Text(title)
                .font(HIGTypography.title.weight(.bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HIGTokens.Spacing.xxl)
                .padding(.bottom, HIGTokens.Spacing.md)
                .minimumScaleFactor(0.85)
            
            Text(description)
                .font(HIGTypography.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, HIGTokens.Spacing.huge)
            
            Spacer(minLength: HIGTokens.Spacing.huge)
        }
    }
}
