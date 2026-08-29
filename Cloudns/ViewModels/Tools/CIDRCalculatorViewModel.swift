import Foundation
import SwiftUI
import Combine

@MainActor
final class CIDRCalculatorViewModel: BaseLoadableViewModel {
    @Published var cidrInput = "192.168.1.0/24"
    @Published var subnetResult: SubnetCalculationResult?
    @Published var subnetError: String?
    
    private let cidrService: CIDRCalculatorServiceProtocol
    
    init(cidrService: CIDRCalculatorServiceProtocol = CIDRCalculatorService.shared) {
        self.cidrService = cidrService
        super.init()
        self.calculateSubnet()
    }
    
    func calculateSubnet() {
        let clean = cidrInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            subnetResult = nil
            subnetError = nil
            return
        }
        
        if let res = cidrService.calculateSubnet(cidr: clean) {
            self.subnetResult = res
            self.subnetError = nil
            self.hasFetchedData = true
        } else {
            self.subnetResult = nil
            self.subnetError = "Invalid CIDR notation (e.g. 192.168.1.0/24)"
        }
    }
}
