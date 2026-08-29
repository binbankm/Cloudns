import SwiftUI

// MARK: - Tail Event Detail Sheet

struct TailEventDetailSheetView: View {
    let event: TailTraceItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Event Info")) {
                    if let outcome = event.outcome {
                        LabeledContent("Outcome", value: outcome)
                    }
                    if let method = event.event?.request?.method {
                        LabeledContent("Method", value: method)
                    }
                    if let url = event.event?.request?.url {
                        LabeledContent("URL") {
                            Text(url).font(.footnote.monospaced())
                        }
                    }
                    if let cron = event.event?.cron {
                        LabeledContent("Cron Trigger", value: cron)
                    }
                }
                
                if let logs = event.logs, !logs.isEmpty {
                    Section(header: Text("Console Logs (\(logs.count))")) {
                        ForEach(logs) { log in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(log.level?.uppercased() ?? "LOG")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.blue)
                                let msg = log.message?.map(\.displayText).joined(separator: " ") ?? ""
                                Text(msg)
                                    .font(.footnote.monospaced())
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                if let exceptions = event.exceptions, !exceptions.isEmpty {
                    Section(header: Text("Exceptions (\(exceptions.count))")) {
                        ForEach(exceptions) { ex in
                            VStack(alignment: .leading, spacing: 4) {
                                if let name = ex.name {
                                    Text(name).font(.caption).foregroundStyle(.red)
                                }
                                if let msg = ex.message {
                                    Text(msg).font(.footnote.monospaced()).foregroundStyle(.red)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .toastContainer()
        }
    }
}
