import SwiftUI

/// A ViewModifier that adds a shimmering animation to any view, commonly used for skeleton loading screens.
public struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    public func body(content: Content) -> some View {
        content
            .modifier(
                AnimatedMask(phase: phase)
            )
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
    
    struct AnimatedMask: AnimatableModifier {
        var phase: CGFloat
        
        var animatableData: CGFloat {
            get { phase }
            set { phase = newValue }
        }
        
        func body(content: Content) -> some View {
            content
                .mask(
                    GeometryReader { geometry in
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .black.opacity(0.3), location: phase - 0.25),
                                .init(color: .black, location: phase),
                                .init(color: .black.opacity(0.3), location: phase + 0.25)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: max(geometry.size.width * 3, 100))
                        .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                    }
                )
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
            .fill(Color(UIColor.tertiarySystemFill))
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
                    .fill(Color(UIColor.tertiarySystemFill))
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
                    .fill(Color(UIColor.tertiarySystemFill))
                    .frame(width: 24, height: 24)
            }
            
            SkeletonBar(width: 120, height: 22, cornerRadius: 6)
            
            SkeletonBar(width: 160, height: 10, cornerRadius: 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
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
                        .fill(Color(UIColor.tertiarySystemFill))
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
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                
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
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                    }
                }
                .cornerRadius(12)
                .clipped()
            }
            .padding(16)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

#Preview("Skeleton Components") {
    VStack(spacing: 20) {
        SkeletonRowView()
        SkeletonCardView()
    }
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}
