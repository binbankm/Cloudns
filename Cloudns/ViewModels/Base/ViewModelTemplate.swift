import Foundation

// MARK: - MVVM ViewModel Standard Architecture Guide

//
// All ViewModels in Cloudns must adhere to the following industrial standards (per AGENTS.md):
// 1. Inherit from `ObservableObject` and be marked with `@MainActor`.
// 2. Drive single-source-of-truth UI with `ViewState<T>` state machine.
// 3. Inject dependencies via `ServicesContainer` (enabling effortless Xcode Previews and Unit Testing).
// 4. Zero retain cycles: use `[weak self]` in closures or rely on async/await structured concurrency.
//
// Below is an illustrative reference implementation:
//
// ```swift
// @MainActor
// final class ZoneDetailViewModel: ObservableObject {
//     @Published private(set) var state: ViewState<Zone> = .idle
//     private let zoneService: ZoneServiceProtocol
//
//     init(zoneService: ZoneServiceProtocol = ServicesContainer.shared.zones) {
//         self.zoneService = zoneService
//     }
//
//     func loadZone(zoneId: String) async {
//         state = .loading
//         do {
//             let zone = try await zoneService.fetchZone(zoneId: zoneId)
//             state = .loaded(zone)
//         } catch {
//             state = .error(message: error.localizedDescription)
//         }
//     }
// }
// ```
