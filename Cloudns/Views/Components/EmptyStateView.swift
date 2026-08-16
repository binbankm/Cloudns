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
                .font(.system(size: 48, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(iconColor ?? .secondary)
                .accessibilityHidden(true)
                .padding(.bottom, 16)
            
            // Title
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 6)
            
            // Message
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 24)
            
            // Actions
            if let actionTitle = actionTitle, let action = action {
                VStack(spacing: 12) {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.body.weight(.medium))
                            .frame(minWidth: 120)
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
                .padding(.top, 20)
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .center)
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

// MARK: - Modern Universal State Overlay (iOS 16 & iOS 17+ Progressive Enhancement)

public struct StateOverlayView: View {
    public enum StateType {
        case empty(icon: String, title: LocalizedStringKey, message: LocalizedStringKey, actionTitle: LocalizedStringKey? = nil, action: (() -> Void)? = nil)
        case search(query: String, clearAction: (() -> Void)? = nil)
        case error(title: LocalizedStringKey = "Unable to Load", message: LocalizedStringKey, retryAction: (() -> Void)? = nil)
    }
    
    public let state: StateType
    
    public init(state: StateType) {
        self.state = state
    }
    
    public var body: some View {
        switch state {
        case .search(let query, let clearAction):
            searchView(query: query, clearAction: clearAction)
        case .error(let title, let message, let retryAction):
            errorView(title: title, message: message, retryAction: retryAction)
        case .empty(let icon, let title, let message, let actionTitle, let action):
            emptyView(icon: icon, title: title, message: message, actionTitle: actionTitle, action: action)
        }
    }
    
    @ViewBuilder
    private func searchView(query: String, clearAction: (() -> Void)?) -> some View {
        if #available(iOS 17.0, *) {
            ContentUnavailableView.search(text: query)
        } else {
            EmptyStateView.search(query: query, action: clearAction)
        }
    }
    
    @ViewBuilder
    private func errorView(title: LocalizedStringKey, message: LocalizedStringKey, retryAction: (() -> Void)?) -> some View {
        if #available(iOS 17.0, *) {
            ContentUnavailableView {
                Label(title, systemImage: "exclamationmark.triangle")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.orange)
            } description: {
                Text(message)
            } actions: {
                if let retryAction {
                    Button("Try Again", action: retryAction)
                        .buttonStyle(.bordered)
                }
            }
        } else {
            EmptyStateView.error(title: title, message: message, retryAction: retryAction)
        }
    }
    
    @ViewBuilder
    private func emptyView(icon: String, title: LocalizedStringKey, message: LocalizedStringKey, actionTitle: LocalizedStringKey?, action: (() -> Void)?) -> some View {
        if #available(iOS 17.0, *) {
            ContentUnavailableView {
                Label(title, systemImage: icon)
            } description: {
                Text(message)
            } actions: {
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .buttonStyle(.borderedProminent)
                }
            }
        } else {
            EmptyStateView(
                icon: icon,
                title: title,
                message: message,
                actionTitle: actionTitle,
                action: action
            )
        }
    }
}
