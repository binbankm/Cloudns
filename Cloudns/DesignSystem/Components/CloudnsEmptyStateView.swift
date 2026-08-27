import SwiftUI

/// A native-styled empty state view matching Apple HIG and ContentUnavailableView design patterns.
public struct CloudnsEmptyStateView: View {
    public let icon: String
    public let title: LocalizedStringKey
    public let message: LocalizedStringKey
    public var iconColor: Color?
    
    // Primary & Secondary Actions
    public var actionTitle: LocalizedStringKey?
    public var action: (() -> Void)?
    public var secondaryActionTitle: LocalizedStringKey?
    public var secondaryAction: (() -> Void)?
    
    public init(
        icon: String,
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        iconColor: Color? = nil,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil,
        secondaryActionTitle: LocalizedStringKey? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.iconColor = iconColor
        self.actionTitle = actionTitle
        self.action = action
        self.secondaryActionTitle = secondaryActionTitle
        self.secondaryAction = secondaryAction
    }
    
    public var body: some View {
        VStack(spacing: CloudnsSpacing.xs) {
            // Icon with Apple-style soft circular badge
            ZStack {
                Circle()
                    .fill((iconColor ?? CloudnsColor.brandAccent).opacity(0.12))
                    .frame(width: CloudnsSize.iconXL, height: CloudnsSize.iconXL)
                
                Image(systemName: icon)
                    .font(CloudnsTypography.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(iconColor ?? CloudnsColor.brandAccent)
            }
            .accessibilityHidden(true)
            .padding(.bottom, CloudnsSpacing.mdLarge)
            
            // Title
            Text(title)
                .font(CloudnsTypography.title3)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.bottom, CloudnsSpacing.xs)
            
            // Message
            Text(message)
                .font(CloudnsTypography.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, CloudnsSpacing.lg)
            
            // Actions
            if let actionTitle = actionTitle, let action = action {
                VStack(spacing: CloudnsSpacing.mdSmall) {
                    CloudnsButton(
                        actionTitle,
                        style: .primary(color: iconColor ?? CloudnsColor.brandAccent),
                        size: .regular,
                        action: action
                    )
                    
                    if let secondaryTitle = secondaryActionTitle, let secondaryAction = secondaryAction {
                        Button {
                            HapticManager.selection()
                            secondaryAction()
                        } label: {
                            Text(secondaryTitle)
                                .font(CloudnsTypography.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, CloudnsSpacing.lg)
            }
        }
        .padding(.vertical, CloudnsSpacing.xl)
        .padding(.horizontal, CloudnsSpacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.96)),
            removal: .opacity
        ))
    }
}

// MARK: - Native Presets
public extension CloudnsEmptyStateView {
    /// Standard empty list state
    static func noData(
        icon: String = "tray",
        title: LocalizedStringKey = "No Data",
        message: LocalizedStringKey = "Nothing to display here yet.",
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) -> CloudnsEmptyStateView {
        CloudnsEmptyStateView(
            icon: icon,
            title: title,
            message: message,
            actionTitle: actionTitle,
            action: action
        )
    }
    
    /// Standard search no results state
    static func search(
        query: String = "",
        action: (() -> Void)? = nil
    ) -> CloudnsEmptyStateView {
        CloudnsEmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: query.isEmpty ? "No items match your search." : "No results found for \"\(query)\". Check spelling or try a different term.",
            actionTitle: action != nil ? "Clear Search" : nil,
            action: action
        )
    }
    
    /// Standard error state with retry
    static func error(
        title: LocalizedStringKey = "Unable to Load",
        message: LocalizedStringKey,
        retryAction: (() -> Void)? = nil
    ) -> CloudnsEmptyStateView {
        CloudnsEmptyStateView(
            icon: "exclamationmark.triangle",
            title: title,
            message: message,
            iconColor: .orange,
            actionTitle: retryAction != nil ? "Try Again" : nil,
            action: retryAction
        )
    }
    
    /// Offline / Network error state
    static func offline(
        retryAction: (() -> Void)? = nil
    ) -> CloudnsEmptyStateView {
        CloudnsEmptyStateView(
            icon: "wifi.slash",
            title: "No Internet Connection",
            message: "Please check your network settings and try again.",
            iconColor: .red,
            actionTitle: retryAction != nil ? "Retry" : nil,
            action: retryAction
        )
    }
}

// MARK: - Typealias Backward Compatibility
public typealias EmptyStateView = CloudnsEmptyStateView
