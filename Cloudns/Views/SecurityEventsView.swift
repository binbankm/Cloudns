import SwiftUI

struct SecurityEventsView: View {
    let zoneId: String
    
    @StateObject private var viewModel = SecurityEventsViewModel()
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)

            if viewModel.isLoading && viewModel.events.isEmpty {
                List {
                    ForEach(0..<6, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
                .listStyle(.insetGrouped)
            } else if let errorMessage = viewModel.errorMessage, viewModel.events.isEmpty {
                EmptyStateView.error(
                    message: LocalizedStringKey(errorMessage),
                    retryAction: {
                        Task {
                            await viewModel.fetchEvents(zoneId: zoneId)
                        }
                    }
                )
            } else if viewModel.events.isEmpty && viewModel.hasFetchedData {
                EmptyStateView(
                    icon: "checkmark.shield",
                    title: "No Security Events",
                    message: "Your site hasn't blocked any threats recently. Everything is secure!"
                )
            } else {
                List {
                    ForEach(viewModel.events) { event in
                        SecurityEventCardView(event: event)
                    }
                }
                .listStyle(.insetGrouped)
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
                Text(actionDisplayName(event.action))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorForAction(event.action).opacity(0.1))
                    .foregroundStyle(colorForAction(event.action))
                    .cornerRadius(6)
                
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
            s.unicodeScalars.append(UnicodeScalar(base + v.value)!)
        }
        return String(s)
    }
    
    private func formatDate(_ isoString: String) -> String {
        DateFormatters.formatISO8601ToDisplay(isoString, style: DateFormatters.mediumDateTime)
    }
}
