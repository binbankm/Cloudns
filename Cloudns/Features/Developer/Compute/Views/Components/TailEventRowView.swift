import SwiftUI

// MARK: - Tail Event Row

struct TailEventRowView: View {
    // MARK: - Properties
    let item: TailTraceItem
    
    var isOk: Bool { item.outcome == "ok" }
    var timestampStr: String {
        guard let ts = item.eventTimestamp else { return "" }
        return DateFormatters.formatTimestampMs(Double(ts))
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
            HStack(spacing: CloudnsSpacing.sm) {
                // Method or Cron badge
                if let method = item.event?.request?.method {
                    Text(method)
                        .font(.caption.monospaced().weight(.bold))
                        .padding(.horizontal, CloudnsSpacing.sm)
                        .padding(.vertical, CloudnsSpacing.xxs)
                        .background(methodColor(method).opacity(0.15))
                        .foregroundStyle(methodColor(method))
                        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.xs))
                } else if let cron = item.event?.cron {
                    Label(cron, systemImage: "clock")
                        .font(.caption.monospaced())
                        .foregroundStyle(.purple)
                }
                
                // Outcome
                CloudnsBadge(isOk ? .active("OK") : .error((item.outcome ?? "Error").uppercased()), isCompact: true)
                
                Spacer()
                
                Text(timestampStr)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            
            // URL
            if let url = item.event?.request?.url {
                Text(url)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            
            // Logs preview
            if let logs = item.logs, !logs.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(logs.prefix(3)) { log in
                        HStack(alignment: .top, spacing: CloudnsSpacing.sm) {
                            Text(log.level?.uppercased() ?? "LOG")
                                .font(.caption2.monospaced().weight(.bold))
                                .foregroundStyle(logLevelColor(log.level))
                            
                            let msg = log.message?.map(\.displayText).joined(separator: " ") ?? ""
                            Text(msg)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    if logs.count > 3 {
                        Text("+ \(logs.count - 3) more log lines")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
                .padding(CloudnsSpacing.sm)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
            }
            
            // Exceptions preview
            if let exceptions = item.exceptions, !exceptions.isEmpty {
                ForEach(exceptions) { ex in
                    HStack(alignment: .top, spacing: CloudnsSpacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .accessibilityHidden(true)
                        Text(ex.message ?? ex.name ?? "Exception occurred")
                            .font(.caption.monospaced())
                            .foregroundStyle(.red)
                            .lineLimit(2)
                    }
                    .padding(CloudnsSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                }
            }
        }
        .padding(.vertical, CloudnsSpacing.xs)
    }
    
    // MARK: - Actions
    private func methodColor(_ method: String) -> Color {
        switch method.uppercased() {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        default: return .purple
        }
    }
    
    private func logLevelColor(_ level: String?) -> Color {
        switch level?.lowercased() {
        case "error": return .red
        case "warn": return .orange
        case "info": return .blue
        default: return .secondary
        }
    }
}
