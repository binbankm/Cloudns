import SwiftUI

// MARK: - NativeStateModifier & State Views
// Apple HIG Declarative state views conforming to standard iOS 16.0+ styling

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

// MARK: - Native State Views (iOS 16+)

public struct NativeLoadingStateView: View {
    public let message: LocalizedStringKey
    
    public init(message: LocalizedStringKey = "Loading…") {
        self.message = message
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

public struct NativeErrorStateView: View {
    public var title: LocalizedStringKey = "Unable to Load"
    public let message: LocalizedStringKey
    public var onRetry: (() -> Void)?
    
    public init(title: LocalizedStringKey = "Unable to Load", message: LocalizedStringKey, onRetry: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.onRetry = onRetry
    }

    public init(title: LocalizedStringKey = "Unable to Load", message: String, onRetry: (() -> Void)? = nil) {
        self.title = title
        self.message = LocalizedStringKey(message)
        self.onRetry = onRetry
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.orange)
            
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            if let onRetry {
                Button("Try Again", action: onRetry)
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

public struct NativeEmptyStateView: View {
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
    
    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            if let description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

public struct NativeSearchEmptyStateView: View {
    public let query: String
    
    public init(query: String) {
        self.query = query
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)
            
            Text("No Results for \"\(query)\"")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text("Check the spelling or try a new search.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

// MARK: - View Extension

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
                NativeLoadingStateView(message: loadingMessage)
            } else if let error, !error.isEmpty {
                NativeErrorStateView(message: error, onRetry: onRetry)
            } else if let searchQuery, !searchQuery.isEmpty {
                NativeSearchEmptyStateView(query: searchQuery)
            } else if isEmpty, let empty {
                NativeEmptyStateView(
                    title: empty.title,
                    systemImage: empty.systemImage,
                    description: empty.description,
                    actionTitle: empty.actionTitle,
                    action: empty.action
                )
            }
        }
    }

    /// Overload allowing direct parameter configuration without instantiating EmptyStateConfig.
    @ViewBuilder
    func listState(
        isLoading: Bool = false,
        loadingMessage: LocalizedStringKey = "Loading…",
        isEmpty: Bool = false,
        emptyTitle: LocalizedStringKey = "No Data",
        emptySystemImage: String = "tray",
        emptyDescription: LocalizedStringKey? = nil,
        emptyActionTitle: LocalizedStringKey? = nil,
        emptyAction: (() -> Void)? = nil,
        isSearchEmpty: Bool = false,
        searchQuery: String = "",
        errorMessage: LocalizedStringKey? = nil,
        retryAction: (() -> Void)? = nil
    ) -> some View {
        overlay {
            if isLoading {
                NativeLoadingStateView(message: loadingMessage)
            } else if let errorMessage {
                NativeErrorStateView(message: errorMessage, onRetry: retryAction)
            } else if isSearchEmpty && !searchQuery.isEmpty {
                NativeSearchEmptyStateView(query: searchQuery)
            } else if isEmpty {
                NativeEmptyStateView(
                    title: emptyTitle,
                    systemImage: emptySystemImage,
                    description: emptyDescription,
                    actionTitle: emptyActionTitle,
                    action: emptyAction
                )
            }
        }
    }
}
