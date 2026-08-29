import Foundation
import SwiftUI
import Combine

@MainActor
final class CIDRCalculatorViewModel: BaseLoadableViewModel {
    @Published var cidrInput: String = "192.168.1.1/24"
    @Published var result: SubnetCalculationResult?
    
    private let cidrService: CIDRCalculatorServiceProtocol
    
    init(cidrService: CIDRCalculatorServiceProtocol = CIDRCalculatorService.shared) {
        self.cidrService = cidrService
        super.init()
        self.calculate()
    }
    
    func calculate() {
        let clean = cidrInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            self.result = nil
            return
        }
        self.result = cidrService.calculateSubnet(cidr: clean)
        self.hasFetchedData = (self.result != nil)
    }
}
