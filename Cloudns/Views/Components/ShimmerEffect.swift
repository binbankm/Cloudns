import SwiftUI

/// A ViewModifier that adds a smooth, Apple HIG standard pulsing shimmer animation to placeholder loading views.
public struct ShimmerEffect: ViewModifier {
    @State private var isPulsing: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init() {}

    public func body(content: Content) -> some View {
        if reduceMotion {
            content
                .opacity(0.8)
        } else {
            content
                .opacity(isPulsing ? 0.45 : 0.95)
                .animation(
                    Animation.easeInOut(duration: 0.85).repeatForever(autoreverses: true),
                    value: isPulsing
                )
                .onAppear {
                    isPulsing = true
                }
        }
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
            modifier(ShimmerEffect())
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
