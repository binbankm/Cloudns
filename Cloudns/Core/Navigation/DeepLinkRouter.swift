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
    
    public func handle(url: URL, currentTab: Binding<AppTab>) {
        guard url.scheme == "cloudns" else { return }
        HapticManager.selection()
        
        let host = (url.host ?? "").lowercased()
        let pathComponents = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        let targetId = pathComponents.first
        
        var newDestination: DeepLinkDestination?
        
        if host == "tools" || host == "devtools" {
            let toolName = pathComponents.first?.lowercased() ?? ""
            switch toolName {
            case "dig": newDestination = .dig
            case "trace": newDestination = .trace
            case "status": newDestination = .status
            case "ipranges": newDestination = .ipranges
            default: currentTab.wrappedValue = .devtools
            }
        } else if host == "zone" || host == "zones" {
            if let id = targetId, !id.isEmpty, id != "placeholder-zone-id", id != "placeholder" {
                newDestination = .zone(id: id)
            } else {
                currentTab.wrappedValue = .domains
            }
        } else if host == "worker" || host == "workers" {
            if let id = targetId, !id.isEmpty, id != "placeholder-worker", id != "placeholder" {
                newDestination = .worker(id: id)
            } else {
                currentTab.wrappedValue = .developer
            }
        } else if host == "pages" || host == "page" {
            if let id = targetId, !id.isEmpty, id != "placeholder-pages", id != "placeholder" {
                newDestination = .pages(id: id)
            } else {
                currentTab.wrappedValue = .developer
            }
        } else if host == "developer" {
            currentTab.wrappedValue = .developer
        } else if host == "devtools" {
            currentTab.wrappedValue = .devtools
        } else if host == "status" {
            newDestination = .status
        } else if host == "dig" {
            newDestination = .dig
        } else if host == "trace" {
            newDestination = .trace
        } else if host == "ipranges" {
            newDestination = .ipranges
        }
        
        if let dest = newDestination {
            self.activeDestination = dest
        }
    }
    
    public func handle(url: URL, currentTab: Binding<Int>) {
        let binding = Binding<AppTab>(
            get: { AppTab(rawValue: currentTab.wrappedValue) ?? .dashboard },
            set: { currentTab.wrappedValue = $0.rawValue }
        )
        handle(url: url, currentTab: binding)
    }
}
