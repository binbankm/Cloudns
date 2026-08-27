import SwiftUI

// MARK: - WorkerBindingHelper

enum WorkerBindingHelper {
    static func icon(for type: String) -> String {
        switch type.lowercased() {
        case "kv_namespace": return "key.fill"
        case "r2_bucket": return "externaldrive.fill"
        case "d1": return "cylinder.split.1x2.fill"
        case "queue": return "tray.2.fill"
        case "service": return "network"
        case "durable_object_namespace": return "cube.fill"
        case "hyperdrive": return "bolt.horizontal.fill"
        case "ai": return "brain.head.profile"
        default: return "shippingbox.fill"
        }
    }
    
    static func badgeTitle(for type: String) -> String {
        switch type.lowercased() {
        case "kv_namespace": return "KV"
        case "r2_bucket": return "R2"
        case "d1": return "D1"
        case "queue": return "QUEUE"
        case "service": return "SERVICE"
        case "ai": return "AI"
        case "hyperdrive": return "HYPERDRIVE"
        default: return type.uppercased()
        }
    }
    
    static func color(for type: String) -> Color {
        switch type.lowercased() {
        case "kv_namespace": return .purple
        case "r2_bucket": return .blue
        case "d1": return .indigo
        case "queue": return .purple
        case "service": return .teal
        case "durable_object_namespace": return .cyan
        case "hyperdrive": return .green
        case "ai": return .pink
        default: return .orange
        }
    }
}
