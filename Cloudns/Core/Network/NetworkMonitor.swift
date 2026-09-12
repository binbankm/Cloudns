import Combine
import Foundation
import Network

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
        monitor = NWPathMonitor()
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                isConnected = (path.status == .satisfied)
                isExpensive = path.isExpensive

                if path.usesInterfaceType(.wifi) {
                    connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    connectionType = .wired
                } else if path.status == .satisfied {
                    connectionType = .other
                } else {
                    connectionType = .none
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
