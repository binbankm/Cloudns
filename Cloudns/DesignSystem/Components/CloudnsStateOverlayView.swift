import SwiftUI

// MARK: - Modern Universal State Overlay (iOS 16 & iOS 17+ Progressive Enhancement)

public struct CloudnsStateOverlayView: View {
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
        ZStack(alignment: .center) {
            Group {
                switch state {
                case .search(let query, let clearAction):
                    searchView(query: query, clearAction: clearAction)
                case .error(let title, let message, let retryAction):
                    errorView(title: title, message: message, retryAction: retryAction)
                case .empty(let icon, let title, let message, let actionTitle, let action):
                    emptyView(icon: icon, title: title, message: message, actionTitle: actionTitle, action: action)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    
    @ViewBuilder
    private func searchView(query: String, clearAction: (() -> Void)?) -> some View {
        if #available(iOS 17.0, *) {
            ContentUnavailableView.search(text: query)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            CloudnsEmptyStateView.search(query: query, action: clearAction)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            CloudnsEmptyStateView.error(title: title, message: message, retryAction: retryAction)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            CloudnsEmptyStateView(
                icon: icon,
                title: title,
                message: message,
                actionTitle: actionTitle,
                action: action
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

// MARK: - Typealias Backward Compatibility
public typealias StateOverlayView = CloudnsStateOverlayView
