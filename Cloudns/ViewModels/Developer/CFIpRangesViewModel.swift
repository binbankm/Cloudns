import Foundation
import SwiftUI
import Combine

@MainActor
final class CFIpRangesViewModel: BaseLoadableViewModel {
    private let devToolsService: DevToolsServiceProtocol
    
    @Published var ipv4List: [String] = []
    @Published var ipv6List: [String] = []
    @Published var selectedSegment = 0 // 0: IPv4, 1: IPv6
    @Published var searchText: String = ""
    
    init(devToolsService: DevToolsServiceProtocol = DevToolsService.shared) {
        self.devToolsService = devToolsService
        super.init()
    }
    
    var filteredIPv4: [String] {
        if searchText.isEmpty { return ipv4List }
        return ipv4List.filter { $0.localizedStandardContains(searchText) }
    }
    
    var filteredIPv6: [String] {
        if searchText.isEmpty { return ipv6List }
        return ipv6List.filter { $0.localizedStandardContains(searchText) }
    }
    
    func fetchIPRanges() async {
        await executeLoadingTask {
            let (v4, v6) = try await self.devToolsService.getCloudflareIPs()
            self.ipv4List = v4
            self.ipv6List = v6
        }
    }
}
