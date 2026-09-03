import SwiftUI

// MARK: - Apple HIG Content State (iOS 16 Baseline + iOS 17+ Progressive Enhancement)
// Strict HIG visual hierarchy for empty, loading, search, and error states

public struct HIGContentState: View {
    public enum Kind {
        case loading(message: LocalizedStringKey = "Loading…")
        case empty(title: LocalizedStringKey, systemImage: String, description: LocalizedStringKey? = nil, actionTitle: LocalizedStringKey? = nil, action: (() -> Void)? = nil)
        case search(query: String)
        case error(title: LocalizedStringKey = "Unable to Load", message: LocalizedStringKey, retryAction: (() -> Void)? = nil)
    }
    
    public let kind: Kind
    
    public init(_ kind: Kind) {
        self.kind = kind
    }
    
    public var body: some View {
        Group {
            if #available(iOS 17.0, *) {
                modernUnavailableView
            } else {
                legacyHIGFallbackView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.higGroupBackground)
    }
    
    @available(iOS 17.0, *)
    @ViewBuilder
    private var modernUnavailableView: some View {
        switch kind {
        case .loading(let message):
            ContentUnavailableView {
                ProgressView()
                    .controlSize(.large)
            } description: {
                Text(message)
            }
        case .search(let query):
            ContentUnavailableView.search(text: query)
        case .error(let title, let message, let retryAction):
            ContentUnavailableView {
                Label(title, systemImage: "exclamationmark.triangle")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(HIGColors.warning)
            } description: {
                Text(message)
            } actions: {
                if let retryAction {
                    Button("Try Again", action: retryAction)
                        .buttonStyle(.bordered)
                }
            }
        case .empty(let title, let systemImage, let description, let actionTitle, let action):
            ContentUnavailableView {
                Label(title, systemImage: systemImage)
                    .symbolRenderingMode(.hierarchical)
            } description: {
                if let description { Text(description) }
            } actions: {
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    @ViewBuilder
    private var legacyHIGFallbackView: some View {
        VStack(spacing: HIGTokens.Spacing.md) {
            switch kind {
            case .loading(let message):
                ProgressView()
                    .controlSize(.large)
                    .padding(.bottom, HIGTokens.Spacing.xs)
                Text(message)
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
            case .search(let query):
                Image(systemName: "magnifyingglass")
                    .font(.system(.largeTitle).weight(.light))
                    .imageScale(.large)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, HIGTokens.Spacing.xs)
                Text("No Results for \"\(query)\"")
                    .font(HIGTypography.title3.weight(.bold))
                    .foregroundStyle(.primary)
                Text("Check the spelling or try a new search.")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            case .error(let title, let message, let retryAction):
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(.largeTitle).weight(.light))
                    .imageScale(.large)
                    .foregroundStyle(HIGColors.warning)
                    .padding(.bottom, HIGTokens.Spacing.xs)
                Text(title)
                    .font(HIGTypography.title3.weight(.bold))
                    .foregroundStyle(.primary)
                Text(message)
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HIGTokens.Spacing.xl)
                if let retryAction {
                    Button("Try Again", action: retryAction)
                        .buttonStyle(.bordered)
                        .padding(.top, HIGTokens.Spacing.sm)
                }
            case .empty(let title, let systemImage, let description, let actionTitle, let action):
                Image(systemName: systemImage)
                    .font(.system(.largeTitle).weight(.light))
                    .imageScale(.large)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, HIGTokens.Spacing.xs)
                Text(title)
                    .font(HIGTypography.title3.weight(.bold))
                    .foregroundStyle(.primary)
                if let description {
                    Text(description)
                        .font(HIGTypography.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HIGTokens.Spacing.xxl)
                }
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .buttonStyle(.borderedProminent)
                        .padding(.top, HIGTokens.Spacing.sm)
                }
            }
        }
        .padding(HIGTokens.Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
