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

// MARK: - Reusable Skeleton Elements

/// A placeholder capsule / rounded bar with system fill color
public struct SkeletonBar: View {
    var width: CGFloat? = nil
    var height: CGFloat = 14
    var cornerRadius: CGFloat = 4
    
    public init(width: CGFloat? = nil, height: CGFloat = 14, cornerRadius: CGFloat = 4) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.tertiarySystemFill))
            .frame(height: height)
            .ifLet(width) { view, w in
                view.frame(width: w)
            }
    }
}

private extension View {
    @ViewBuilder
    func ifLet<T>(_ value: T?, transform: (Self, T) -> some View) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Row Skeletons

/// A standard skeleton row that mimics a typical native list item (e.g. icon, title, subtitle, trailing badge)
public struct SkeletonRowView: View {
    var hasIcon: Bool
    var hasSubtitle: Bool
    var hasTrailing: Bool
    
    public init(hasIcon: Bool = true, hasSubtitle: Bool = true, hasTrailing: Bool = true) {
        self.hasIcon = hasIcon
        self.hasSubtitle = hasSubtitle
        self.hasTrailing = hasTrailing
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            if hasIcon {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 36, height: 36)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                SkeletonBar(width: 140, height: 14, cornerRadius: 4)
                
                if hasSubtitle {
                    SkeletonBar(width: 200, height: 11, cornerRadius: 4)
                }
            }
            
            Spacer()
            
            if hasTrailing {
                SkeletonBar(width: 44, height: 16, cornerRadius: 6)
            }
        }
        .padding(.vertical, 6)
        .shimmering()
    }
}

/// A grouped list skeleton showing multiple row placeholders
public struct SkeletonListView: View {
    var count: Int
    var sectionHeader: String?
    
    public init(count: Int = 5, sectionHeader: String? = nil) {
        self.count = count
        self.sectionHeader = sectionHeader
    }
    
    public var body: some View {
        List {
            Section(header: sectionHeader != nil ? Text(sectionHeader!) : nil) {
                ForEach(0..<count, id: \.self) { _ in
                    SkeletonRowView()
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Card & Dashboard Skeletons

/// A placeholder card for stats, overview metrics, and quick action tiles
public struct SkeletonCardView: View {
    var height: CGFloat
    
    public init(height: CGFloat = 110) {
        self.height = height
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonBar(width: 80, height: 12, cornerRadius: 4)
                Spacer()
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 24, height: 24)
            }
            
            SkeletonBar(width: 120, height: 22, cornerRadius: 6)
            
            SkeletonBar(width: 160, height: 10, cornerRadius: 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shimmering()
    }
}

/// A comprehensive skeleton placeholder for Domain / Zone Detail page
public struct SkeletonDetailView: View {
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card Skeleton
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 60, height: 60)
                    
                    SkeletonBar(width: 180, height: 20, cornerRadius: 6)
                    SkeletonBar(width: 110, height: 14, cornerRadius: 4)
                    
                    HStack(spacing: 12) {
                        SkeletonBar(width: 70, height: 24, cornerRadius: 12)
                        SkeletonBar(width: 90, height: 24, cornerRadius: 12)
                    }
                    .padding(.top, 4)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // 2-column Grid Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    SkeletonCardView(height: 95)
                    SkeletonCardView(height: 95)
                    SkeletonCardView(height: 95)
                    SkeletonCardView(height: 95)
                }
                
                // Section List Skeleton
                VStack(spacing: 1) {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonRowView(hasIcon: true, hasSubtitle: true, hasTrailing: true)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.secondarySystemGroupedBackground))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }
}
/// A pixel-matched skeleton for Metric cards
public struct MetricCardSkeleton: View {
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SkeletonBar(width: 32, height: 32, cornerRadius: 8)
                Spacer()
                SkeletonBar(width: 44, height: 18, cornerRadius: 9)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                SkeletonBar(width: 60, height: 26, cornerRadius: 6)
                SkeletonBar(width: 90, height: 13, cornerRadius: 4)
            }
            .padding(.top, 2)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// A pixel-matched skeleton for Zone / Domain row card
public struct ZoneCardSkeleton: View {
    public init() {}
    
    public var body: some View {
        HStack(spacing: 12) {
            SkeletonBar(width: 36, height: 36, cornerRadius: 10)
            
            VStack(alignment: .leading, spacing: 5) {
                SkeletonBar(width: 130, height: 16, cornerRadius: 4)
                SkeletonBar(width: 80, height: 12, cornerRadius: 3)
            }
            
            Spacer()
            
            SkeletonBar(width: 50, height: 20, cornerRadius: 10)
        }
        .padding(.vertical, 4)
    }
}

#Preview("Skeleton Components") {
    VStack(spacing: 20) {
        MetricCardSkeleton()
        ZoneCardSkeleton()
        SkeletonRowView()
        SkeletonCardView()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
