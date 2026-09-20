import Combine
import Foundation

@MainActor
final class HyperdriveViewModel: BaseLoadableViewModel {
    let accountId: String
    private let hyperdriveService: HyperdriveServiceProtocol

    @Published var configs: [HyperdriveConfig] = []
    @Published var searchText: String = ""

    init(accountId: String, hyperdriveService: HyperdriveServiceProtocol = HyperdriveService.shared) {
        self.accountId = accountId
        self.hyperdriveService = hyperdriveService
        super.init()
    }

    var filteredConfigs: [HyperdriveConfig] {
        if searchText.isEmpty {
            return configs
        }
        return configs.filter { $0.name.localizedStandardContains(searchText) || ($0.origin?.host ?? "").localizedStandardContains(searchText) }
    }

    func fetchConfigs() async {
        await executeLoadingTask {
            self.configs = try await self.hyperdriveService.listHyperdriveConfigs(accountId: self.accountId)
        }
    }

    func createConfig(payload: HyperdriveCreate) async -> Bool {
        do {
            _ = try await hyperdriveService.createHyperdriveConfig(accountId: accountId, payload: payload)
            await fetchConfigs()
            return true
        } catch {
            return false
        }
    }

    func deleteConfig(id: String) async {
        do {
            try await hyperdriveService.deleteHyperdriveConfig(accountId: accountId, configId: id)
            await fetchConfigs()
        } catch {}
    }

    func updateCaching(configId: String, disabled: Bool, maxAge: Int?, staleWhileRevalidate: Int?) async -> HyperdriveConfig? {
        do {
            let caching = HyperdriveCaching(disabled: disabled, maxAge: maxAge, staleWhileRevalidate: staleWhileRevalidate)
            let patch = HyperdrivePatch(caching: caching)
            let updated = try await hyperdriveService.updateHyperdriveConfig(accountId: accountId, configId: configId, payload: patch)
            await fetchConfigs()
            return updated
        } catch {
            return nil
        }
    }

    func fetchMetrics(configId: String) async -> HyperdriveMetrics? {
        do {
            return try await hyperdriveService.getHyperdriveMetrics(accountId: accountId, configId: configId)
        } catch {
            return nil
        }
    }
}
