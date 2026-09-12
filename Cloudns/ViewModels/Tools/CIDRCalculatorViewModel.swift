import Combine
import Foundation

@MainActor
final class CIDRCalculatorViewModel: BaseLoadableViewModel {
    @Published var cidrInput = "192.168.1.0/24"
    @Published var subnetResult: SubnetCalculationResult?
    @Published var subnetError: String?

    private let cidrService: CIDRCalculatorServiceProtocol

    init(cidrService: CIDRCalculatorServiceProtocol = CIDRCalculatorService.shared) {
        self.cidrService = cidrService
        super.init()
        calculateSubnet()
    }

    func calculateSubnet() {
        let clean = cidrInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            subnetResult = nil
            subnetError = nil
            return
        }

        if let res = cidrService.calculateSubnet(cidr: clean) {
            subnetResult = res
            subnetError = nil
            hasFetchedData = true
        } else {
            subnetResult = nil
            subnetError = "Invalid CIDR notation (e.g. 192.168.1.0/24)"
        }
    }
}
