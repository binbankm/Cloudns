import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    // MARK: - Properties
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
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // 1. Dynamic Ambient Aurora Glow Background
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
                // 2. Top Bar: Brand Title & Skip Action
                HStack {
                    HStack(spacing: CloudnsSpacing.sm) {
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
                        HapticManager.impact(.light)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            hasSeenOnboarding = true
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, CloudnsSpacing.mdSmall)
                    .padding(.vertical, CloudnsSpacing.sm)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, CloudnsSpacing.lg)
                .padding(.top, CloudnsSpacing.mdSmall)
                
                // 3. Tab Pages
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
                    HapticManager.selection()
                }
                
                // 4. Bottom Controls: Capsule Indicator & Action Button
                VStack(spacing: CloudnsSpacing.mdLarge) {
                    // Modern Capsule Page Indicator
                    HStack(spacing: CloudnsSpacing.sm) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? currentColor : Color.secondary.opacity(0.25))
                                .frame(width: currentPage == index ? 24 : 7, height: 7)
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    .padding(.vertical, CloudnsSpacing.xs)
                    
                    // Main Action Button (Gradient Aurora)
                    Button(action: {
                        if currentPage < totalPages - 1 {
                            HapticManager.impact(.light)
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                currentPage += 1
                            }
                        } else {
                            HapticManager.impact(.medium)
                            withAnimation(.easeInOut(duration: 0.3)) {
                                hasSeenOnboarding = true
                            }
                        }
                    }) {
                        HStack(spacing: CloudnsSpacing.sm) {
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
                        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.lg))
                        .cloudnsShadow(.brand(color: currentColor, radius: 12, y: 5))
                    }
                    .padding(.horizontal, CloudnsSpacing.lg)
                }
                .padding(.bottom, CloudnsSpacing.xl)
            }
            .centerConstrainedWidth(maxWidth: 520)
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingView()
}
