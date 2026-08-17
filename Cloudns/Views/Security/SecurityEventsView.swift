import SwiftUI

struct SecurityEventsView: View {
    let zoneId: String
    
    @StateObject private var viewModel = SecurityEventsViewModel()
    
    var body: some View {
        List {
            if !viewModel.events.isEmpty {
                Section {
                    ForEach(viewModel.events) { event in
                        SecurityEventCardView(event: event)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.events.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchEvents(zoneId: zoneId) }
                            }
                        )
                    )
                } else if viewModel.events.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "checkmark.shield",
                            title: "No Security Events",
                            message: "Your site hasn't blocked any threats recently. Everything is secure!"
                        )
                    )
                }
            }
        }
        .navigationTitle("Security Events")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchEvents(zoneId: zoneId)
            }
        }
        .refreshable {
            await viewModel.fetchEvents(zoneId: zoneId)
        }
    }
}

struct SecurityEventCardView: View {
    let event: SecurityEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                CloudnsBadge(.custom(color: colorForAction(event.action), text: actionDisplayName(event.action)), isCompact: true)
                
                Spacer()
                
                Text(formatDate(event.datetime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("IP Address")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        Text(countryFlag(countryCode: event.clientCountryName))
                        Text(event.clientIP)
                            .font(.subheadline.monospacedDigit())
                    }
                }
                
                Spacer()
                
                if let asn = event.clientAsn {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("ASN")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("AS\(asn)")
                            .font(.subheadline)
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Source / Engine")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(event.source.capitalized)
                    .font(.footnote)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Target URL")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(event.host)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func actionDisplayName(_ action: String) -> String {
        switch action {
        case "block": return "BLOCK"
        case "challenge": return "LEGACY CAPTCHA"
        case "js_challenge": return "JS CHALLENGE"
        case "managed_challenge": return "MANAGED CHALLENGE"
        case "log": return "LOG"
        case "connectionClose": return "CONNECTION CLOSE"
        default: return action.uppercased()
        }
    }
    
    private func colorForAction(_ action: String) -> Color {
        switch action {
        case "block", "connectionClose": return .red
        case "challenge", "js_challenge", "managed_challenge": return .orange
        case "log": return .blue
        default: return .gray
        }
    }
    
    private func countryFlag(countryCode: String) -> String {
        let base: UInt32 = 127397
        var s = ""
        for v in countryCode.unicodeScalars {
            if let scalar = UnicodeScalar(base + v.value) {
                s.unicodeScalars.append(scalar)
            }
        }
        return s
    }
    
    private func formatDate(_ isoString: String) -> String {
        DateFormatters.formatISO8601ToDisplay(isoString, style: DateFormatters.mediumDateTime)
    }
}
