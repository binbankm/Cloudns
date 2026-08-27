import SwiftUI

// MARK: - Tail Event Detail Sheet

struct TailEventDetailSheetView: View {
    // MARK: - Properties
    let event: TailTraceItem
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
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
                            VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                                Text(log.level?.uppercased() ?? "LOG")
                                    .font(CloudnsTypography.caption2.weight(.medium))
                                    .foregroundStyle(CloudnsColor.brand)
                                let msg = log.message?.map(\.displayText).joined(separator: " ") ?? ""
                                Text(msg)
                                    .font(CloudnsTypography.code)
                            }
                            .padding(.vertical, CloudnsSpacing.xxs)
                        }
                    }
                }
                
                if let exceptions = event.exceptions, !exceptions.isEmpty {
                    Section(header: Text("Exceptions (\(exceptions.count))")) {
                        ForEach(exceptions) { ex in
                            VStack(alignment: .leading, spacing: CloudnsSpacing.xs) {
                                if let name = ex.name {
                                    Text(name)
                                        .font(CloudnsTypography.caption)
                                        .foregroundStyle(CloudnsColor.danger)
                                }
                                if let msg = ex.message {
                                    Text(msg)
                                        .font(CloudnsTypography.code)
                                        .foregroundStyle(CloudnsColor.danger)
                                }
                            }
                            .padding(.vertical, CloudnsSpacing.xxs)
                        }
                    }
                }
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .toastContainer()
        }
    }
}
