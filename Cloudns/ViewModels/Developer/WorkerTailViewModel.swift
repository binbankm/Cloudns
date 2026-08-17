import Foundation
import SwiftUI
import Combine

@MainActor
class WorkerTailViewModel: BaseLoadableViewModel {
    let accountId: String
    let scriptName: String
    private let apiClient = CloudflareAPIClient.shared
    
    @Published var isStreaming = false
    @Published var events: [TailTraceItem] = []
    @Published var searchText = ""
    @Published var selectedFilter = 0 // 0: All, 1: Logs Only, 2: Exceptions Only
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var currentSessionId: String?
    private var isTaskCancelled = false
    
    init(accountId: String, scriptName: String) {
        self.accountId = accountId
        self.scriptName = scriptName
        super.init()
    }
    
    var filteredEvents: [TailTraceItem] {
        var list = events
        if selectedFilter == 1 {
            list = list.filter { ($0.logs?.isEmpty == false) }
        } else if selectedFilter == 2 {
            list = list.filter { ($0.exceptions?.isEmpty == false) || ($0.outcome != "ok" && $0.outcome != nil) }
        }
        
        if searchText.isEmpty { return list }
        return list.filter { item in
            if let url = item.event?.request?.url, url.localizedCaseInsensitiveContains(searchText) { return true }
            if let logs = item.logs {
                for log in logs {
                    if let msgs = log.message {
                        for m in msgs {
                            if m.displayText.localizedCaseInsensitiveContains(searchText) { return true }
                        }
                    }
                }
            }
            if let exceptions = item.exceptions {
                for ex in exceptions {
                    if let msg = ex.message, msg.localizedCaseInsensitiveContains(searchText) { return true }
                }
            }
            return false
        }
    }
    
    func startStream() async {
        guard !isStreaming else { return }
        errorMessage = nil
        isStreaming = true
        isTaskCancelled = false
        
        do {
            let session = try await apiClient.createWorkerTailSession(accountId: accountId, scriptName: scriptName)
            self.currentSessionId = session.id
            guard let url = URL(string: session.url) else {
                throw APIError.invalidURL
            }
            
            let task = URLSession.shared.webSocketTask(with: url, protocols: ["trace-v1"])
            self.webSocketTask = task
            task.resume()
            
            // Send trace-v1 filter setup
            try await task.send(.string(#"{"filters":[],"debug":false}"#))
            
            startReceiveLoop(for: task)
        } catch {
            self.errorMessage = "Failed to connect: \(error.localizedDescription)"
            self.isStreaming = false
        }
    }
    
    private func startReceiveLoop(for task: URLSessionWebSocketTask) {
        Task { [weak self] in
            while true {
                guard let self = self, self.isStreaming, !self.isTaskCancelled else { break }
                do {
                    let message = try await task.receive()
                    let data: Data?
                    switch message {
                    case .string(let text):
                        data = text.data(using: .utf8)
                    case .data(let d):
                        data = d
                    @unknown default:
                        data = nil
                    }
                    
                    if let d = data, let item = try? JSONDecoder().decode(TailTraceItem.self, from: d) {
                        self.events.insert(item, at: 0)
                        if self.events.count > 500 {
                            self.events.removeLast()
                        }
                    }
                } catch {
                    if !self.isTaskCancelled {
                        self.errorMessage = "Disconnected: \(error.localizedDescription)"
                        self.isStreaming = false
                    }
                    break
                }
            }
        }
    }
    
    func stopStream() {
        isTaskCancelled = true
        isStreaming = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        if let sid = currentSessionId {
            Task {
                try? await apiClient.deleteWorkerTailSession(accountId: accountId, scriptName: scriptName, tailId: sid)
            }
            currentSessionId = nil
        }
    }
    
    func clearLogs() {
        events.removeAll()
    }
}
