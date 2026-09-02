import Foundation
import SwiftUI
import Combine

@MainActor
public protocol LoadableViewModelProtocol: ObservableObject {
    var isLoading: Bool { get set }
    var hasFetchedData: Bool { get set }
    var errorMessage: String? { get set }
}

@MainActor
open class BaseLoadableViewModel: ObservableObject, LoadableViewModelProtocol {
    @Published public var isLoading: Bool = false
    @Published public var hasFetchedData: Bool = false
    @Published public var errorMessage: String?
    public var lastFetchTime: Date?
    
    public var isStale: Bool {
        guard let last = lastFetchTime else { return true }
        return Date().timeIntervalSince(last) > 180
    }
    
    public init() {}
    
    public func executeLoadingTask(
        clearError: Bool = true,
        action: () async throws -> Void
    ) async {
        isLoading = true
        if clearError {
            errorMessage = nil
        }
        
        do {
            try Task.checkCancellation()
            try await action()
            self.lastFetchTime = Date()
        } catch is CancellationError {
            // Task was cancelled by SwiftUI lifecycle or manual cancellation; do not treat as an error
        } catch {
            errorMessage = APIError.formatCloudflareError(error.localizedDescription)
        }
        
        hasFetchedData = true
        isLoading = false
    }
    
    public func resetLoadingState() {
        self.isLoading = false
        self.hasFetchedData = false
        self.errorMessage = nil
        self.lastFetchTime = nil
    }
    
    public func executeSWR<T: Codable & Sendable>(
        cacheKey: String,
        targetType: T.Type,
        onCached: @MainActor @Sendable @escaping (T) -> Void,
        fetcher: @Sendable @escaping () async throws -> T,
        onFresh: @MainActor @Sendable @escaping (T) -> Void
    ) async {
        let initialEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
        let scopedKey = SWRCacheStore.accountScopedKey(cacheKey)
        
        if let cached = await SWRCacheStore.shared.get(forKey: scopedKey, as: targetType) {
            onCached(cached)
            self.hasFetchedData = true
        }
        
        if !self.hasFetchedData {
            self.isLoading = true
        }
        
        do {
            try Task.checkCancellation()
            let fresh = try await fetcher()
            
            let currentEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
            guard currentEmail == initialEmail && !currentEmail.isEmpty else {
                self.isLoading = false
                return
            }
            
            onFresh(fresh)
            self.hasFetchedData = true
            self.lastFetchTime = Date()
            self.errorMessage = nil
            await SWRCacheStore.shared.set(fresh, forKey: scopedKey)
        } catch is CancellationError {
            // Task was cancelled by SwiftUI lifecycle or manual cancellation; do not treat as an error
        } catch {
            let currentEmail = UserDefaults.standard.string(forKey: AppStorageKey.activeAccountEmail) ?? ""
            if currentEmail == initialEmail && !self.hasFetchedData {
                self.errorMessage = APIError.formatCloudflareError(error.localizedDescription)
            }
        }
        self.isLoading = false
    }
    
    public func executeSWR<T: Codable & Sendable>(
        cacheKey: String,
        onStale: @MainActor @Sendable @escaping (T) -> Void,
        fetcher: @Sendable @escaping () async throws -> T,
        onFresh: @MainActor @Sendable @escaping (T) -> Void
    ) async {
        await executeSWR(
            cacheKey: cacheKey,
            targetType: T.self,
            onCached: onStale,
            fetcher: fetcher,
            onFresh: onFresh
        )
    }
}
