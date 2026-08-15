import SwiftUI

/// A native-styled empty state view matching Apple HIG and ContentUnavailableView design patterns.
public struct EmptyStateView: View {
    public let icon: String
    public let title: LocalizedStringKey
    public let message: LocalizedStringKey
    public var iconColor: Color? = nil
    
    // Primary & Secondary Actions
    public var actionTitle: LocalizedStringKey? = nil
    public var action: (() -> Void)? = nil
    public var secondaryActionTitle: LocalizedStringKey? = nil
    public var secondaryAction: (() -> Void)? = nil
    
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
        VStack(spacing: 0) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 52, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(iconColor ?? .secondary)
                .padding(.bottom, 16)
            
            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
            
            // Message
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 28)
            
            // Actions
            if let actionTitle = actionTitle, let action = action {
                VStack(spacing: 12) {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.body)
                            .frame(minWidth: 140)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    
                    if let secondaryTitle = secondaryActionTitle, let secondaryAction = secondaryAction {
                        Button(action: secondaryAction) {
                            Text(secondaryTitle)
                                .font(.subheadline)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.top, 24)
            }
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, minHeight: 340, alignment: .center)
    }
}

// MARK: - Native Presets
public extension EmptyStateView {
    /// Standard empty list state
    static func noData(
        icon: String = "tray",
        title: LocalizedStringKey = "No Data",
        message: LocalizedStringKey = "Nothing to display here yet.",
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) -> EmptyStateView {
        EmptyStateView(
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
    ) -> EmptyStateView {
        EmptyStateView(
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
    ) -> EmptyStateView {
        EmptyStateView(
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
    ) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "No Internet Connection",
            message: "Please check your network settings and try again.",
            iconColor: .red,
            actionTitle: retryAction != nil ? "Retry" : nil,
            action: retryAction
        )
    }
}

#Preview("Standard Empty") {
    EmptyStateView(
        icon: "globe",
        title: "No Domains Found",
        message: "You haven't connected any Cloudflare domains to this account yet.",
        actionTitle: "Add Domain",
        action: {}
    )
}

#Preview("Search No Results") {
    EmptyStateView.search(query: "example.com", action: {})
}

#Preview("Error State") {
    EmptyStateView.error(
        message: "The Cloudflare API request timed out. Please check your network.",
        retryAction: {}
    )
}
