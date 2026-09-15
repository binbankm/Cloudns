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

// MARK: - Gentle Banner Component View

public struct GentleBannerView: View {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    public let data: GentleBannerData
    public var onDismiss: () -> Void

    public var body: some View {
        HStack(spacing: GentleSpacing.sm) {
            Image(systemName: data.type.iconName)
                .font(GentleTypography.headline)
                .foregroundStyle(data.type.tintColor)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(data.title))
                    .font(GentleTypography.cardTitle)
                    .foregroundStyle(GentleColor.textPrimary)
                    .lineLimit(1)

                if let message = data.message {
                    Text(LocalizedStringKey(message))
                        .font(GentleTypography.caption)
                        .foregroundStyle(GentleColor.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: GentleSpacing.xs)

            Button {
                GentleHaptics.soft()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(GentleTypography.captionSmall)
                    .foregroundStyle(GentleColor.textSecondary.opacity(0.8))
                    .padding(6)
                    .background(GentleColor.textSecondary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Dismiss notification"))
        }
        .padding(.horizontal, GentleSpacing.md)
        .padding(.vertical, GentleSpacing.sm + 2)
        .background(GentleColor.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: GentleCornerRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: GentleCornerRadius.card, style: .continuous)
                .stroke(
                    colorSchemeContrast == .increased
                        ? data.type.tintColor
                        : data.type.tintColor.opacity(0.25),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 6)
        .padding(.horizontal, GentleSpacing.md)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    if value.translation.height < -15 {
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
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .zIndex(999)
                .padding(.top, 4)
            }
        }
    }
}

public extension View {
    /// Mounts global floating gentle notification banner overlay to the view hierarchy
    func gentleBannerOverlay() -> some View {
        modifier(GentleBannerOverlayModifier())
    }
}
