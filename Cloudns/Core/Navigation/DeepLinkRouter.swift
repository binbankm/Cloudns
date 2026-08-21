import Foundation
import SwiftUI
import Combine

// MARK: - DeepLinkDestination

public enum DeepLinkDestination: Identifiable, Equatable, Sendable {
    case zone(id: String)
    case worker(id: String)
    case pages(id: String)
    case dig
    case trace
    case status
    case ipranges
    
    public var id: String {
        switch self {
        case .zone(let id): return "zone_\(id)"
        case .worker(let id): return "worker_\(id)"
        case .pages(let id): return "pages_\(id)"
        case .dig: return "dig"
        case .trace: return "trace"
        case .status: return "status"
        case .ipranges: return "ipranges"
        }
    }
}

// MARK: - DeepLinkRouter

@MainActor
public final class DeepLinkRouter: ObservableObject {
    public static let shared = DeepLinkRouter()
    
    @Published public var activeDestination: DeepLinkDestination?
    
    private init() {}
    
    public func handle(url: URL, currentTab: Binding<Int>) {
        guard url.scheme == "cloudns" else { return }
        HapticManager.selection()
        
        let host = (url.host ?? "").lowercased()
        let path = url.path.lowercased()
        let fullUrl = url.absoluteString.lowercased()
        let lastComponent = url.lastPathComponent
        
        var newDestination: DeepLinkDestination?
        
        if host == "tools" || fullUrl.contains("tools") {
            if path.contains("dig") || fullUrl.contains("dig") {
                newDestination = .dig
            } else if path.contains("trace") || fullUrl.contains("trace") {
                newDestination = .trace
            } else if path.contains("status") || fullUrl.contains("status") {
                newDestination = .status
            } else if path.contains("ipranges") || fullUrl.contains("ipranges") {
                newDestination = .ipranges
            } else {
                currentTab.wrappedValue = 2
            }
        } else if host == "zone" || fullUrl.contains("cloudns://zone") {
            if !lastComponent.isEmpty && lastComponent != "/" && lastComponent != "zone" && lastComponent != "placeholder-zone-id" && lastComponent != "placeholder" {
                newDestination = .zone(id: lastComponent)
            } else {
                currentTab.wrappedValue = 1
            }
        } else if fullUrl.contains("worker") || host == "worker" || host == "workers" {
            if !lastComponent.isEmpty && lastComponent != "/" && lastComponent != "worker" && lastComponent != "workers" && lastComponent != "placeholder-worker" && lastComponent != "placeholder" {
                newDestination = .worker(id: lastComponent)
            } else {
                currentTab.wrappedValue = 2
            }
        } else if fullUrl.contains("pages") || host == "pages" || host == "page" {
            if !lastComponent.isEmpty && lastComponent != "/" && lastComponent != "pages" && lastComponent != "page" && lastComponent != "placeholder-pages" && lastComponent != "placeholder" {
                newDestination = .pages(id: lastComponent)
            } else {
                currentTab.wrappedValue = 2
            }
        } else if host == "developer" || fullUrl.contains("developer") {
            currentTab.wrappedValue = 2
        } else if host == "status" || fullUrl.contains("status") {
            newDestination = .status
        } else if host == "dig" || fullUrl.contains("dig") {
            newDestination = .dig
        } else if host == "trace" || fullUrl.contains("trace") {
            newDestination = .trace
        } else if host == "ipranges" || fullUrl.contains("ipranges") {
            newDestination = .ipranges
        }
        
        if let dest = newDestination {
            if activeDestination != nil {
                activeDestination = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.activeDestination = dest
                }
            } else {
                self.activeDestination = dest
            }
        }
    }
}
