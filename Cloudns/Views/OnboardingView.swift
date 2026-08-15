import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
            
            VStack {
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        icon: "network",
                        title: "Manage Domains",
                        description: "Effortlessly manage your Cloudflare zones, DNS records, and settings from anywhere.",
                        color: .blue
                    )
                    .tag(0)
                    
                    OnboardingPage(
                        icon: "shield.fill",
                        title: "Ultimate Security",
                        description: "Quickly enable Under Attack Mode, manage WAF, and tweak security levels when you need it most.",
                        color: .green
                    )
                    .tag(1)
                    
                    OnboardingPage(
                        icon: "bolt.fill",
                        title: "Lightning Fast",
                        description: "Purge cache instantly, enable dev mode, and optimize your site's performance with a tap.",
                        color: .orange
                    )
                    .tag(2)
                    
                    OnboardingPage(
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
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        withAnimation {
                            hasSeenOnboarding = true
                        }
                    }
                }) {
                    Text(currentPage == 3 ? "Get Started" : "Next")
                        .font(.body)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let color: Color
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Image(systemName: icon)
                    .font(.system(size: 80))
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
            }
            
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 16)
            
            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
