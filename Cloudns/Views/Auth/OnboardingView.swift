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
                    HStack(spacing: 6) {
                        Image(systemName: "cloud.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("Cloudns")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    Button("Skip") {
                        HIGFeedback.impact(.light)
                        completeOnboarding()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                
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
                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? currentColor : Color.secondary.opacity(0.25))
                                .frame(width: currentPage == index ? 24 : 7, height: 7)
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    .padding(.vertical, 4)
                    
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
                        HStack(spacing: 8) {
                            Text(currentPage == totalPages - 1 ? "Get Started" : "Continue")
                                .font(.body.weight(.semibold))
                            
                            Image(systemName: currentPage == totalPages - 1 ? "checkmark" : "arrow.right")
                                .font(.subheadline.weight(.bold))
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
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: currentColor.opacity(0.35), radius: 12, x: 0, y: 5)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 28)
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
                    .fill(Color(.secondarySystemGroupedBackground).opacity(0.85))
                    .frame(width: 140, height: 140)
                    .shadow(color: color.opacity(0.25), radius: 16, x: 0, y: 8)
                
                Image(systemName: icon)
                    .font(.system(.largeTitle, design: .rounded).weight(.semibold))
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
            
            Spacer(minLength: 24)
            
            Text(badgeText)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(color.opacity(0.12))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
                .padding(.bottom, 12)
            
            Text(title)
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 10)
                .minimumScaleFactor(0.85)
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
            
            Spacer(minLength: 40)
        }
    }
}
