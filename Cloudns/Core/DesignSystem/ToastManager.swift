import SwiftUI
import Combine

// MARK: - Toast Item Model

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
        iconColor: Color = .green,
        duration: TimeInterval = 2.0
    ) {
        self.message = message
        self.icon = icon
        self.iconColor = iconColor
        self.duration = duration
    }
}

// MARK: - Toast Manager (Singleton)

@MainActor
public final class ToastManager: ObservableObject {
    public static let shared = ToastManager()

    @Published public private(set) var currentToast: ToastItem?
    private var dismissTask: Task<Void, Never>?

    private init() { }

    /// 显示普通提示
    public func show(
        _ message: LocalizedStringKey,
        icon: String = "info.circle.fill",
        iconColor: Color = .blue,
        duration: TimeInterval = 2.0
    ) {
        let item = ToastItem(message: message, icon: icon, iconColor: iconColor, duration: duration)
        present(item)
    }

    /// 显示成功提示
    public func showSuccess(_ message: LocalizedStringKey, icon: String = "checkmark.circle.fill") {
        HIGFeedback.success()
        let item = ToastItem(message: message, icon: icon, iconColor: .green, duration: 2.0)
        present(item)
    }

    /// 显示已复制提示
    public func showCopied(_ message: LocalizedStringKey = "Copied to Clipboard") {
        HIGFeedback.success()
        let item = ToastItem(message: message, icon: "doc.on.doc.fill", iconColor: .blue, duration: 1.8)
        present(item)
    }

    /// 显示错误提示
    public func showError(_ message: LocalizedStringKey, icon: String = "exclamationmark.triangle.fill") {
        HIGFeedback.error()
        let item = ToastItem(message: message, icon: icon, iconColor: .red, duration: 2.5)
        present(item)
    }

    /// 关闭当前提示
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

    public init() { }

    public var body: some View {
        Group {
            if let toast = toastManager.currentToast {
                HStack(spacing: 8) {
                    Image(systemName: toast.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(toast.iconColor)

                    Text(toast.message)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
                .padding(.top, 8)
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
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: toastManager.currentToast)
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
