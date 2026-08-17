import Foundation
import SwiftUI
import Combine

@MainActor
class CloudflareStatusViewModel: BaseLoadableViewModel {
    @Published var summary: CFStatusSummary?
    
    func fetchStatus() async {
        await executeLoadingTask {
            guard let url = URL(string: "https://www.cloudflarestatus.com/api/v2/summary.json") else {
                throw APIError.invalidURL
            }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw APIError.invalidResponse
            }
            let decoded = try JSONDecoder().decode(CFStatusSummary.self, from: data)
            self.summary = decoded
        }
    }
}
