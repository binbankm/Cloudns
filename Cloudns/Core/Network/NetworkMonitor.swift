import Foundation
import Network
import Combine

/// 全局响应式网络连接状态监控器
/// 基于 Apple Network.framework 的 NWPathMonitor，提供低功耗、实时的网络可达性与蜂窝网感知。
@MainActor
public final class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()
    
    @Published public private(set) var isConnected: Bool = true
    @Published public private(set) var isExpensive: Bool = false
    @Published public private(set) var connectionType: ConnectionType = .wifi
    
    public enum ConnectionType: String, Sendable {
        case wifi = "Wi-Fi"
        case cellular = "Cellular"
        case wired = "Ethernet"
        case other = "Other"
        case none = "None"
    }
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.cloudns.network.monitor", qos: .utility)
    
    private init() {
        self.monitor = NWPathMonitor()
        self.startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isConnected = (path.status == .satisfied)
                self.isExpensive = path.isExpensive
                
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .wired
                } else if path.status == .satisfied {
                    self.connectionType = .other
                } else {
                    self.connectionType = .none
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
