import Foundation
import Network

/// 负责在新用户启动或进入登录页时静默预热网络通道，唤起国行 iOS 设备的蜂窝与无线网络权限弹窗。
public enum NetworkPreheater {
    @MainActor private static var hasPreheated = false
    
    /// 触发系统网络权限静默唤起
    @MainActor
    public static func warmup() {
        guard !hasPreheated else { return }
        hasPreheated = true
        
        Task.detached(priority: .utility) {
            guard let url = URL(string: "https://1.1.1.1/cdn-cgi/trace") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 4.0
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            
            // 发起轻量 HEAD 请求唤醒系统网络授权通道
            _ = try? await URLSession.shared.data(for: request)
        }
    }
}
