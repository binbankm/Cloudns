import SwiftUI

// MARK: - OnboardingPageView

struct OnboardingPageView: View {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let color: Color
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 160, height: 160)
                
                Image(systemName: icon)
                    .font(.system(size: 80))
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
            }
            
            Text(title)
                .font(.title.weight(.bold))
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
