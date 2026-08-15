import SwiftUI
import Combine

// MARK: - Toast Type Definition
public enum ToastType: Equatable {
    case success
    case error
    case warning
    case info
    case copied
    
    var iconName: String {
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
    
    var iconColor: Color {
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
            return .accentColor
        }
    }
    
    func playHaptic() {
        switch self {
        case .success, .copied:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .info:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

// MARK: - Toast Item Model
public struct ToastItem: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let message: String?
    public let type: ToastType
    public let duration: Double
    
    public init(title: String, message: String? = nil, type: ToastType = .info, duration: Double = 2.5) {
        self.title = title
        self.message = message
        self.type = type
        self.duration = duration
    }
}

// MARK: - Toast Manager
@MainActor
public final class ToastManager: ObservableObject {
    public static let shared = ToastManager()
    
    @Published public var currentToast: ToastItem? = nil
    private var dismissTask: Task<Void, Never>? = nil
    
    private init() {}
    
    public func show(title: String, message: String? = nil, type: ToastType = .info, duration: Double = 2.5) {
        dismissTask?.cancel()
        
        type.playHaptic()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            self.currentToast = ToastItem(title: title, message: message, type: type, duration: duration)
        }
        
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self.dismiss()
        }
    }
    
    public func showSuccess(_ title: String, message: String? = nil) {
        show(title: title, message: message, type: .success)
    }
    
    public func showError(_ title: String, message: String? = nil) {
        show(title: title, message: message, type: .error, duration: 3.5)
    }
    
    public func showCopied(_ text: String = "Copied to clipboard") {
        show(title: text, type: .copied, duration: 2.0)
    }
    
    public func showInfo(_ title: String, message: String? = nil) {
        show(title: title, message: message, type: .info)
    }
    
    public func showWarning(_ title: String, message: String? = nil) {
        show(title: title, message: message, type: .warning, duration: 3.0)
    }
    
    public func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            self.currentToast = nil
        }
    }
}

// MARK: - Floating Capsule Banner View
public struct ToastBannerView: View {
    let item: ToastItem
    let onDismiss: () -> Void
    @State private var dragOffset: CGFloat = 0
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.type.iconName)
                .font(.title3)
                .foregroundColor(item.type.iconColor)
                .symbolRenderingMode(.multicolor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(item.title))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let msg = item.message, !msg.isEmpty {
                    Text(LocalizedStringKey(msg))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.14), radius: 18, x: 0, y: 8)
        .padding(.horizontal, 20)
        .offset(y: min(0, dragOffset))
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height < 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height < -20 {
                        onDismiss()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onTapGesture {
            onDismiss()
        }
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
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    )
                )
                .zIndex(9999)
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
