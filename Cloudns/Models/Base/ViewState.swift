import Foundation

// MARK: - ViewState Machine (AGENTS.md 规范)

/// Unified generic UI state machine for ViewModels and Views.
/// Eliminates multiple scattered boolean flags (isLoading, isError, hasData).
public enum ViewState<T>: Equatable where T: Equatable {
    /// Initial idle state
    case idle
    /// Loading state (triggers gentle skeleton shimmer or progress)
    case loading
    /// Successfully loaded state with strongly-typed data payload
    case loaded(T)
    /// Empty data state with comforting guidance message
    case empty(message: String)
    /// Error state with humane, actionable guidance message
    case error(message: String)

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var data: T? {
        if case let .loaded(data) = self { return data }
        return nil
    }
}
