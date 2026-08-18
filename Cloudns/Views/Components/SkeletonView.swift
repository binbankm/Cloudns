import SwiftUI

/// A ViewModifier that adds a smooth, industry-standard shimmering light-sweep animation to any view.
public struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = -1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init() {}

    public func body(content: Content) -> some View {
        if reduceMotion {
            content
                .opacity(0.8)
        } else {
            content
                .overlay(
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: Color.white.opacity(0.35), location: 0.45),
                                .init(color: Color.white.opacity(0.6), location: 0.5),
                                .init(color: Color.white.opacity(0.35), location: 0.55),
                                .init(color: .clear, location: 1.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: max(width * 2.0, 150))
                        .offset(x: -width + (width * 2.5 * phase))
                        .blendMode(.screen)
                        .animation(
                            Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                            value: phase
                        )
                    }
                    .mask(content)
                )
                .onAppear {
                    phase = 1.0
                }
        }
    }
}

public extension View {
    /// Applies a shimmering effect to the view conditionally.
    @ViewBuilder
    func shimmering(active: Bool = true) -> some View {
        if active {
            modifier(ShimmerEffect())
        } else {
            self
        }
    }
    
    /// Applies standard HIG placeholder redaction with smooth shimmer fallback for loading state
    @ViewBuilder
    func skeletonLoading(_ isLoading: Bool) -> some View {
        self
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmering(active: isLoading)
            .allowsHitTesting(!isLoading)
            .disabled(isLoading)
    }
}
