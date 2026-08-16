import Foundation
import SwiftUI
import Combine

/// 统一的基础加载状态协议与类，规范所有 ViewModel 的加载、错误与刷新生命周期
@MainActor
public protocol LoadableViewModelProtocol: ObservableObject {
    var isLoading: Bool { get set }
    var hasFetchedData: Bool { get set }
    var errorMessage: String? { get set }
}

@MainActor
open class BaseViewModel: ObservableObject, LoadableViewModelProtocol {
    @Published public var isLoading: Bool = false
    @Published public var hasFetchedData: Bool = false
    @Published public var errorMessage: String? = nil
    
    public init() {}
    
    /// 统一异步任务执行包装器，自动处理 loading 状态与 error 捕获
    public func executeLoadingTask(
        clearError: Bool = true,
        action: () async throws -> Void
    ) async {
        isLoading = true
        if clearError {
            errorMessage = nil
        }
        
        do {
            try await action()
            hasFetchedData = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
