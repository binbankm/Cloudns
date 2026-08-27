import SwiftUI

/// A ViewModifier that adds a smooth, Apple HIG standard sweep linear gradient shimmer animation to placeholder loading views.
public struct CloudnsShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = -1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    
    public init() {}

    public func body(content: Content) -> some View {
        if reduceMotion {
            content.opacity(0.8)
        } else {
            content
                .overlay {
                    GeometryReader { proxy in
                        let size = proxy.size
                        let maxDimension = max(size.width, size.height, 100)
                        
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: shimmerColor.opacity(0.35), location: 0.35),
                                .init(color: shimmerColor, location: 0.5),
                                .init(color: shimmerColor.opacity(0.35), location: 0.65),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .scaleEffect(2.5)
                        .offset(x: phase * maxDimension * 2.0)
                    }
                    .mask(content)
                }
                .onAppear {
                    withAnimation(
                        .linear(duration: 1.6)
                        .repeatForever(autoreverses: false)
                    ) {
                        phase = 1.0
                    }
                }
        }
    }
    
    private var shimmerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.18) : Color.white.opacity(0.75)
    }
}

// MARK: - Adaptive Toggle Style for Skeleton Redaction

public struct CloudnsAdaptiveToggleStyle: ToggleStyle {
    @Environment(\.redactionReasons) private var redactionReasons
    
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        if redactionReasons.contains(.placeholder) {
            HStack {
                configuration.label
                Spacer()
                Capsule()
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 51, height: 31)
            }
        } else {
            Toggle(configuration)
        }
    }
}

public extension View {
    /// Applies a shimmering effect to the view conditionally.
    @ViewBuilder
    func shimmering(active: Bool = true) -> some View {
        if active {
            modifier(CloudnsShimmerEffect())
        } else {
            self
        }
    }
    
    /// Applies standard HIG placeholder redaction with smooth shimmer fallback for loading state
    @ViewBuilder
    func skeletonLoading(_ isLoading: Bool) -> some View {
        self
            .toggleStyle(CloudnsAdaptiveToggleStyle())
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmering(active: isLoading)
            .allowsHitTesting(!isLoading)
            .disabled(isLoading)
    }
}

// MARK: - Typealias Backward Compatibility
public typealias ShimmerEffect = CloudnsShimmerEffect
