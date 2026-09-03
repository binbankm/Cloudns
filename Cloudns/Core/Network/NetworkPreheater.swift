import Foundation
import Network

public enum NetworkPreheater {
    @MainActor private static var hasPreheated = false
    
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
            
            _ = try? await URLSession.shared.data(for: request)
        }
    }
}
