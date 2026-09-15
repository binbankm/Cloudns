import Combine
import SwiftUI

// MARK: - Gentle Banner Type

public enum GentleBannerType: Equatable {
    case info
    case success
    case warning
    case danger
    case offline

    public var iconName: String {
        switch self {
        case .info:
            "info.circle.fill"
        case .success:
            "checkmark.circle.fill"
        case .warning:
            "exclamationmark.triangle.fill"
        case .danger:
            "exclamationmark.octagon.fill"
        case .offline:
            "wifi.slash"
        }
    }

    public var tintColor: Color {
        switch self {
        case .info:
            GentleColor.skyBlue
        case .success:
            GentleColor.statusActive
        case .warning:
            GentleColor.statusWarning
        case .danger:
            GentleColor.statusDanger
        case .offline:
            GentleColor.accent
        }
    }
}

// MARK: - Gentle Banner Data

public struct GentleBannerData: Identifiable, Equatable {
    public let id: UUID
    public let type: GentleBannerType
    public let title: String
    public let message: String?
    public let duration: TimeInterval?

    public init(
        id: UUID = UUID(),
        type: GentleBannerType,
        title: String,
        message: String? = nil,
        duration: TimeInterval? = 3.5
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.duration = duration
    }

    public static func == (lhs: GentleBannerData, rhs: GentleBannerData) -> Bool {
        lhs.id == rhs.id && lhs.type == rhs.type && lhs.title == rhs.title && lhs.message == rhs.message
    }
}

// MARK: - Gentle Banner Global Manager

@MainActor
public final class GentleBannerManager: ObservableObject {
    public static let shared = GentleBannerManager()

    @Published public var currentBanner: GentleBannerData?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    public func show(
        type: GentleBannerType,
        title: String,
        message: String? = nil,
        duration: TimeInterval? = 3.5
    ) {
        dismissTask?.cancel()

        let banner = GentleBannerData(
            type: type,
            title: title,
            message: message,
            duration: duration
        )

        withAnimation(GentleAnimation.gentleExpand) {
            self.currentBanner = banner
        }

        switch type {
        case .success:
            GentleHaptics.success()
        case .warning, .offline:
            GentleHaptics.warning()
        case .danger:
            GentleHaptics.warning()
        case .info:
            GentleHaptics.soft()
        }

        if let duration {
            dismissTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.dismiss()
                }
            }
        }
    }

    public func showOffline(message: String = "Network connection seems interrupted · Please check and tap to retry") {
        show(type: .offline, title: "Offline", message: message, duration: 4.5)
    }

    public func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        withAnimation(GentleAnimation.gentleExpand) {
            self.currentBanner = nil
        }
    }
}

// MARK: - Gentle Banner Component View (Apple Dynamic Pill Style)

public struct GentleBannerView: View {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    public let data: GentleBannerData
    public var onDismiss: () -> Void

    public var body: some View {
        HStack(spacing: GentleSpacing.xs) {
            Image(systemName: data.type.iconName)
                .font(GentleTypography.footnoteSemibold)
                .foregroundStyle(data.type.tintColor)
                .frame(width: 18, height: 18)
                .accessibilityHidden(true)

            if let message = data.message, !message.isEmpty {
                VStack(alignment: .leading, spacing: 1) {
                    Text(LocalizedStringKey(data.title))
                        .font(GentleTypography.footnoteSemibold)
                        .foregroundStyle(GentleColor.textPrimary)

                    Text(LocalizedStringKey(message))
                        .font(GentleTypography.captionSmall)
                        .foregroundStyle(GentleColor.textSecondary)
                }
            } else {
                Text(LocalizedStringKey(data.title))
                    .font(GentleTypography.footnoteSemibold)
                    .foregroundStyle(GentleColor.textPrimary)
            }
        }
        .padding(.horizontal, GentleSpacing.md)
        .padding(.vertical, GentleSpacing.xs + 2)
        .background(
            Capsule()
                .fill(GentleColor.cardSurface.opacity(0.92))
        )
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(
                    colorSchemeContrast == .increased
                        ? data.type.tintColor
                        : data.type.tintColor.opacity(0.25),
                    lineWidth: 0.8
                )
        )
        .shadow(color: Color.black.opacity(0.09), radius: 14, x: 0, y: 5)
        .fixedSize(horizontal: true, vertical: false)
        .contentShape(Capsule())
        .onTapGesture {
            GentleHaptics.light()
            onDismiss()
        }
        .gesture(
            DragGesture(minimumDistance: 8)
                .onEnded { value in
                    if value.translation.height < -8 {
                        onDismiss()
                    }
                }
        )
    }
}

// MARK: - Banner Overlay View Modifier

public struct GentleBannerOverlayModifier: ViewModifier {
    @ObservedObject private var manager = GentleBannerManager.shared

    public func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if let banner = manager.currentBanner {
                GentleBannerView(data: banner) {
                    manager.dismiss()
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.92)),
                    removal: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.92))
                ))
                .zIndex(999)
                .padding(.top, GentleSpacing.xs)
            }
        }
        .animation(GentleAnimation.spring, value: manager.currentBanner)
    }
}

public extension View {
    /// Mounts global floating gentle notification banner overlay to the view hierarchy
    func gentleBannerOverlay() -> some View {
        modifier(GentleBannerOverlayModifier())
    }
}
