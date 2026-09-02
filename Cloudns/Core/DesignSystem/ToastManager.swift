import SwiftUI
import Combine

// MARK: - Apple HIG Toast Item Model

public struct ToastItem: Identifiable, Equatable {
    public let id = UUID()
    public let message: LocalizedStringKey
    public let icon: String
    public let iconColor: Color
    public let duration: TimeInterval

    public static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.id == rhs.id
    }

    public init(
        message: LocalizedStringKey,
        icon: String = "checkmark.circle.fill",
        iconColor: Color = HIGColors.success,
        duration: TimeInterval = 2.0
    ) {
        self.message = message
        self.icon = icon
        self.iconColor = iconColor
        self.duration = duration
    }
}

// MARK: - Toast Manager (Singleton & Concurrency Safe)

@MainActor
public final class ToastManager: ObservableObject {
    public static let shared = ToastManager()

    @Published public private(set) var currentToast: ToastItem?
    private var dismissTask: Task<Void, Never>?

    private init() { }

    /// Presents standard informational toast HUD
    public func show(
        _ message: LocalizedStringKey,
        icon: String = "info.circle.fill",
        iconColor: Color = HIGColors.info,
        duration: TimeInterval = 2.0
    ) {
        let item = ToastItem(message: message, icon: icon, iconColor: iconColor, duration: duration)
        present(item)
    }

    /// Presents success toast HUD with haptic feedback
    public func showSuccess(_ message: LocalizedStringKey, icon: String = "checkmark.circle.fill") {
        HIGFeedback.success()
        let item = ToastItem(message: message, icon: icon, iconColor: HIGColors.success, duration: 2.0)
        present(item)
    }

    /// Presents copied-to-clipboard toast HUD with haptic feedback
    public func showCopied(_ message: LocalizedStringKey = "Copied to Clipboard") {
        HIGFeedback.copied()
        let item = ToastItem(message: message, icon: "doc.on.doc.fill", iconColor: HIGColors.info, duration: 1.8)
        present(item)
    }

    /// Presents error toast HUD with haptic feedback
    public func showError(_ message: LocalizedStringKey, icon: String = "exclamationmark.triangle.fill") {
        HIGFeedback.error()
        let item = ToastItem(message: message, icon: icon, iconColor: HIGColors.error, duration: 2.5)
        present(item)
    }

    /// Dismisses current toast HUD
    public func dismiss() {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            self.currentToast = nil
        }
    }

    private func present(_ toast: ToastItem) {
        dismissTask?.cancel()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            self.currentToast = toast
        }

        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(toast.duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                if self.currentToast?.id == toast.id {
                    self.currentToast = nil
                }
            }
        }
    }
}

// MARK: - HIG Toast Overlay Component (Apple Capsule HUD)

public struct HIGToastOverlay: View {
    @ObservedObject private var toastManager = ToastManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() { }

    public var body: some View {
        Group {
            if let toast = toastManager.currentToast {
                HStack(spacing: HIGTokens.Spacing.sm) {
                    Image(systemName: toast.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(toast.iconColor)

                    Text(toast.message)
                        .font(HIGTypography.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .padding(.horizontal, HIGTokens.Spacing.lg)
                .padding(.vertical, HIGTokens.Spacing.md - 2)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.08), lineWidth: HIGTokens.Elevation.overlayStroke)
                )
                .shadow(
                    color: Color.black.opacity(0.12),
                    radius: HIGTokens.Elevation.overlayShadowRadius,
                    x: 0,
                    y: HIGTokens.Elevation.overlayShadowY
                )
                .padding(.top, HIGTokens.Spacing.sm)
                .onTapGesture {
                    toastManager.dismiss()
                }
                .gesture(
                    DragGesture(minimumDistance: 10, coordinateSpace: .local)
                        .onEnded { value in
                            if value.translation.height < 0 {
                                toastManager.dismiss()
                            }
                        }
                )
                .zIndex(999)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.85)),
                    removal: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9))
                ))
            }
        }
        .animation(HIGMotion.overlaySpring(reduceMotion: reduceMotion), value: toastManager.currentToast)
    }
}

public struct HIGToastModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                HIGToastOverlay()
            }
    }
}

public extension View {
    func higToast() -> some View {
        self.modifier(HIGToastModifier())
    }
}
