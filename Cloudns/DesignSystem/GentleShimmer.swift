import SwiftUI

// MARK: - Gentle Shimmer Modifier (Skeleton Loading)

public struct GentleShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    public func body(content: Content) -> some View {
        if reduceMotion {
            content
                .opacity(0.8)
        } else {
            content
                .overlay(
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: geo.size.width * 2)
                        .offset(x: -geo.size.width + (phase * geo.size.width * 2))
                    }
                )
                .mask(content)
                .onAppear {
                    withAnimation(
                        .linear(duration: 1.6)
                            .repeatForever(autoreverses: false)
                    ) {
                        phase = 1
                    }
                }
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Adds a gentle breathing shimmer effect for loading skeletons
    func gentleShimmer() -> some View {
        modifier(GentleShimmerModifier())
    }
}
