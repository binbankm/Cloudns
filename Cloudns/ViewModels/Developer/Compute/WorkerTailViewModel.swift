import Combine
import Foundation
import SwiftUI

@MainActor
final class WorkerTailViewModel: BaseLoadableViewModel {
    let accountId: String
    let scriptName: String
    private let workerService: WorkerServiceProtocol

    @Published var isStreaming = false
    @Published var events: [TailTraceItem] = []
    @Published var searchText = ""
    @Published var selectedFilter = 0 // 0: All, 1: Logs Only, 2: Exceptions Only

    private var webSocketTask: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var currentSessionId: String?
    private var isTaskCancelled = false

    init(accountId: String, scriptName: String, workerService: WorkerServiceProtocol = WorkerService.shared) {
        self.accountId = accountId
        self.scriptName = scriptName
        self.workerService = workerService
        super.init()
    }

    var filteredEvents: [TailTraceItem] {
        var list = events
        if selectedFilter == 1 {
            list = list.filter { ($0.logs?.isEmpty == false) }
        } else if selectedFilter == 2 {
            list = list.filter { ($0.exceptions?.isEmpty == false) || ($0.outcome != "ok" && $0.outcome != nil) }
        }

        if searchText.isEmpty {
            return list
        }
        return list.filter { item in
            if let url = item.event?.request?.url, url.localizedStandardContains(searchText) {
                return true
            }
            if let logs = item.logs {
                for log in logs {
                    if let msgs = log.message {
                        for m in msgs where m.displayText.localizedStandardContains(searchText) {
                            return true
                        }
                    }
                }
            }
            if let exceptions = item.exceptions {
                for ex in exceptions where ex.message?.localizedStandardContains(searchText) == true {
                    return true
                }
            }
            return false
        }
    }

    func clearLogs() {
        events = []
    }

    func startStream(clearPrevious: Bool = true) async {
        guard !isStreaming else { return }
        errorMessage = nil
        if clearPrevious {
            events = []
        }
        isStreaming = true
        isTaskCancelled = false

        do {
            let session = try await workerService.createWorkerTailSession(accountId: accountId, scriptName: scriptName)
            currentSessionId = session.id
            guard let url = URL(string: session.url) else {
                throw APIError.invalidURL
            }

            let task = URLSession.shared.webSocketTask(with: url, protocols: ["trace-v1"])
            webSocketTask = task
            task.resume()

            // Send trace-v1 filter setup
            try await task.send(.string(#"{"filters":[],"debug":false}"#))

            startReceiveLoop(for: task)
        } catch {
            errorMessage = "Failed to connect: \(error.localizedDescription)"
            isStreaming = false
        }
    }

    private func startReceiveLoop(for task: URLSessionWebSocketTask) {
        receiveTask?.cancel()
        receiveTask = Task { [weak self] in
            var buffer: [TailTraceItem] = []
            var lastFlush = Date()

            while !Task.isCancelled {
                guard let self, isStreaming, !self.isTaskCancelled else { break }
                do {
                    let message = try await task.receive()
                    let data: Data? = switch message {
                    case let .string(text):
                        text.data(using: .utf8)
                    case let .data(d):
                        d
                    @unknown default:
                        nil
                    }

                    if let d = data, let item = try? JSONDecoder().decode(TailTraceItem.self, from: d) {
                        buffer.insert(item, at: 0)
                    }

                    let now = Date()
                    if buffer.count >= 20 || now.timeIntervalSince(lastFlush) >= 0.15 {
                        if !buffer.isEmpty {
                            let batch = buffer
                            buffer.removeAll(keepingCapacity: true)
                            lastFlush = now
                            await MainActor.run {
                                var merged = batch + self.events
                                if merged.count > 500 {
                                    merged = Array(merged.prefix(500))
                                }
                                self.events = merged
                            }
                        }
                    }
                } catch {
                    if !isTaskCancelled, !Task.isCancelled {
                        errorMessage = "Disconnected: \(error.localizedDescription)"
                        isStreaming = false
                    }
                    break
                }
            }
        }
    }

    func stopStream() {
        isTaskCancelled = true
        isStreaming = false
        receiveTask?.cancel()
        receiveTask = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil

        if let sid = currentSessionId {
            Task {
                try? await workerService.deleteWorkerTailSession(accountId: accountId, scriptName: scriptName, tailId: sid)
            }
            currentSessionId = nil
        }
    }
}
