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
    
    public init(errorMessage: String, title: LocalizedStringKey = "Unable to Load", onRetry: (() -> Void)? = nil) {
        self.title = title
        self.message = LocalizedStringKey(errorMessage)
        self.onRetry = onRetry
    }
    
    public init(errorMessage: LocalizedStringKey, title: LocalizedStringKey = "Unable to Load", onRetry: (() -> Void)? = nil) {
        self.title = title
        self.message = errorMessage
        self.onRetry = onRetry
    }
    
    public var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.orange.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.orange.opacity(0.25), radius: 8, x: 0, y: 4)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 2)
            
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
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
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
    
    public init(
        icon: String,
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.systemImage = icon
        self.description = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public init(
        icon: String,
        title: LocalizedStringKey,
        message: String,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.systemImage = icon
        self.description = LocalizedStringKey(message)
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 76, height: 76)
                    .shadow(color: themeManager.accentColor.opacity(0.25), radius: 10, x: 0, y: 5)
                
                Image(systemName: systemImage)
                    .font(.system(size: 34, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 4)
            
            Text(title)
                .font(.headline.weight(.semibold))
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
                    .tint(themeManager.accentColor)
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
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.secondary.opacity(0.24), Color.secondary.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 28, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 2)
            
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
