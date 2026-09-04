import SwiftUI

// MARK: - NativeStateModifier
// Declarative state overlay for lists and screens conforming to Apple HIG

public struct EmptyStateConfig {
    public let title: LocalizedStringKey
    public let systemImage: String
    public var description: LocalizedStringKey?
    public var actionTitle: LocalizedStringKey?
    public var action: (() -> Void)?
    
    public init(
        title: LocalizedStringKey,
        systemImage: String,
        description: LocalizedStringKey? = nil,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }
}

public extension View {
    /// Declarative view state overlay handling loading, errors, search results, and empty states.
    /// iOS 16.0+ compatible, replacing 30+ lines of duplicated branching in each screen.
    @ViewBuilder
    func listState(
        isLoading: Bool = false,
        loadingMessage: LocalizedStringKey = "Loading…",
        error: String? = nil,
        isEmpty: Bool = false,
        empty: EmptyStateConfig? = nil,
        searchQuery: String? = nil,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        overlay {
            if isLoading {
                HIGContentState(.loading(message: loadingMessage))
            } else if let error, !error.isEmpty {
                HIGContentState(.error(message: LocalizedStringKey(error), retryAction: onRetry))
            } else if let searchQuery, !searchQuery.isEmpty {
                HIGContentState(.search(query: searchQuery))
            } else if isEmpty, let empty {
                HIGContentState(
                    .empty(
                        title: empty.title,
                        systemImage: empty.systemImage,
                        description: empty.description,
                        actionTitle: empty.actionTitle,
                        action: empty.action
                    )
                )
            }
        }
    }
}
