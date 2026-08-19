import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    OnboardingPageView(
                        icon: "network",
                        title: "Manage Domains",
                        description: "Effortlessly manage your Cloudflare zones, DNS records, and settings from anywhere.",
                        color: .blue
                    )
                    .tag(0)
                    
                    OnboardingPageView(
                        icon: "shield.fill",
                        title: "Ultimate Security",
                        description: "Quickly enable Under Attack Mode, manage WAF, and tweak security levels when you need it most.",
                        color: .green
                    )
                    .tag(1)
                    
                    OnboardingPageView(
                        icon: "bolt.fill",
                        title: "Lightning Fast",
                        description: "Purge cache instantly, enable dev mode, and optimize your site's performance with a tap.",
                        color: .orange
                    )
                    .tag(2)
                    
                    OnboardingPageView(
                        icon: "faceid",
                        title: "Private & Secure",
                        description: "Protect your Cloudflare account data with Face ID / Touch ID app lock.",
                        color: .purple
                    )
                    .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                Button(action: {
                    if currentPage < 3 {
                        HapticManager.impact(.light)
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        HapticManager.impact(.medium)
                        withAnimation {
                            hasSeenOnboarding = true
                        }
                    }
                }) {
                    Text(currentPage == 3 ? "Get Started" : "Next")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    OnboardingView()
}
