import SwiftUI
import Combine

// MARK: - Toast Type Definition
public enum ToastType: Equatable {
    case success
    case error
    case warning
    case info
    case copied
    
    public var iconName: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        case .copied:
            return "doc.on.doc.fill"
        }
    }
    
    public var iconColor: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        case .warning:
            return .orange
        case .info:
            return .blue
        case .copied:
            return .blue
        }
    }
    
    public var badgeBgColor: Color {
        switch self {
        case .success:
            return Color.green.opacity(0.15)
        case .error:
            return Color.red.opacity(0.15)
        case .warning:
            return Color.orange.opacity(0.15)
        case .info:
            return Color.blue.opacity(0.15)
        case .copied:
            return Color.blue.opacity(0.15)
        }
    }
    
    @MainActor
    public func playHaptic() {
        switch self {
        case .success, .copied:
            HapticManager.notification(.success)
        case .error:
            HapticManager.notification(.error)
        case .warning:
            HapticManager.notification(.warning)
        case .info:
            HapticManager.impact(.light)
        }
    }
}

// MARK: - Toast Item Model
public struct ToastItem: Identifiable, Equatable {
    public let id: UUID
    public let title: String
    public let message: String?
    public let type: ToastType
    public let duration: Double
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String,
        message: String? = nil,
        type: ToastType = .info,
        duration: Double = 2.5,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.type = type
        self.duration = duration
        self.createdAt = createdAt
    }
    
    public static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast Manager
@MainActor
public final class ToastManager: ObservableObject {
    public static let shared = ToastManager()
    
    @Published public var currentToast: ToastItem? = nil
    
    private var dismissTask: Task<Void, Never>? = nil
    private var isPaused = false
    private var remainingDuration: Double = 0
    private var lastShowTimestamp: Date = .distantPast
    
    private init() {}
    
    public func show(
        title: String,
        message: String? = nil,
        type: ToastType = .info,
        duration: Double = 2.5
    ) {
        let now = Date()
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanMessage = message?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Deduplication / Debounce: If exact same notification was triggered in < 1.2s, simply extend timer
        if let current = currentToast,
           current.title == cleanTitle,
           current.message == cleanMessage,
           current.type == type,
           now.timeIntervalSince(lastShowTimestamp) < 1.2 {
            scheduleDismissal(duration: duration)
            return
        }
        
        lastShowTimestamp = now
        dismissTask?.cancel()
        isPaused = false
        remainingDuration = duration
        
        type.playHaptic()
        
        withAnimation(.spring(response: 0.38, dampingFraction: 0.78, blendDuration: 0)) {
            self.currentToast = ToastItem(
                title: cleanTitle,
                message: cleanMessage,
                type: type,
                duration: duration,
                createdAt: now
            )
        }
        
        scheduleDismissal(duration: duration)
    }
    
    public func showSuccess(_ title: String, message: String? = nil) {
        show(title: title, message: message, type: .success, duration: 2.5)
    }
    
    public func showError(_ title: String, message: String? = nil) {
        show(title: title, message: message, type: .error, duration: 3.5)
    }
    
    public func showCopied(_ text: String = "Copied to clipboard") {
        show(title: text, type: .copied, duration: 2.0)
    }
    
    public func showInfo(_ title: String, message: String? = nil) {
        show(title: title, message: message, type: .info, duration: 2.5)
    }
    
    public func showWarning(_ title: String, message: String? = nil) {
        show(title: title, message: message, type: .warning, duration: 3.0)
    }
    
    public func pause() {
        guard currentToast != nil, !isPaused else { return }
        isPaused = true
        dismissTask?.cancel()
        dismissTask = nil
    }
    
    public func resume() {
        guard currentToast != nil, isPaused else { return }
        isPaused = false
        scheduleDismissal(duration: max(1.5, remainingDuration))
    }
    
    private func scheduleDismissal(duration: Double) {
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self.dismiss()
        }
    }
    
    public func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        isPaused = false
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            self.currentToast = nil
        }
    }
}

// MARK: - Floating Dynamic Island Banner View
public struct ToastBannerView: View {
    let item: ToastItem
    let onDismiss: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isPressing = false
    
    public var body: some View {
        HStack(spacing: 12) {
            // Tinted Icon Badge
            ZStack {
                Circle()
                    .fill(item.type.badgeBgColor)
                    .frame(width: 32, height: 32)
                
                Image(systemName: item.type.iconName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(item.type.iconColor)
            }
            .accessibilityHidden(true)
            
            // Text Content
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(item.title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if let msg = item.message, !msg.isEmpty {
                    Text(LocalizedStringKey(msg))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer(minLength: 8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
        .padding(.horizontal, 16)
        .scaleEffect(isPressing ? 0.98 : 1.0)
        .offset(y: min(0, dragOffset))
        .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.8), value: isPressing)
        .gesture(
            DragGesture(minimumDistance: 4)
                .onChanged { value in
                    ToastManager.shared.pause()
                    if value.translation.height < 0 {
                        dragOffset = value.translation.height
                    } else {
                        // Dampen downward drag with rubber-banding
                        dragOffset = sqrt(value.translation.height) * 2
                    }
                }
                .onEnded { value in
                    if value.translation.height < -15 || value.predictedEndTranslation.height < -50 {
                        onDismiss()
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            dragOffset = 0
                        }
                        ToastManager.shared.resume()
                    }
                }
        )
        .onTapGesture {
            onDismiss()
        }
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressing = pressing
            if pressing {
                ToastManager.shared.pause()
            } else {
                ToastManager.shared.resume()
            }
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.message ?? "")")
        .accessibilityHint("Swipe up or tap to dismiss")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - View Container & Modifier
public struct ToastContainerModifier: ViewModifier {
    @ObservedObject private var manager = ToastManager.shared
    
    public func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if let toast = manager.currentToast {
                ToastBannerView(item: toast) {
                    manager.dismiss()
                }
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top)
                            .combined(with: .scale(scale: 0.94, anchor: .top))
                            .combined(with: .opacity),
                        removal: .move(edge: .top)
                            .combined(with: .scale(scale: 0.94, anchor: .top))
                            .combined(with: .opacity)
                    )
                )
                .zIndex(99999)
                .padding(.top, 4)
            }
        }
    }
}

public extension View {
    /// Attaches the native toast notification banner container to the view hierarchy.
    func toastContainer() -> some View {
        self.modifier(ToastContainerModifier())
    }
}

#Preview("Toast Previews") {
    VStack(spacing: 20) {
        ToastBannerView(
            item: ToastItem(title: "Copied to clipboard", message: "192.0.2.1 was copied", type: .copied),
            onDismiss: {}
        )
        
        ToastBannerView(
            item: ToastItem(title: "DNS Record Saved", message: "Record A -> 1.1.1.1 created successfully", type: .success),
            onDismiss: {}
        )
        
        ToastBannerView(
            item: ToastItem(title: "Purge Cache Failed", message: "API error code 10000", type: .error),
            onDismiss: {}
        )
    }
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}
