import SwiftUI

struct CloudflareStatusView: View {
    @StateObject private var viewModel = CloudflareStatusViewModel()
    
    var body: some View {
        contentView
            .navigationTitle("System Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let url = URL(string: "https://www.cloudflarestatus.com") {
                        Link(destination: url) {
                            Image(systemName: "safari")
                                .accessibilityLabel("Open Statuspage in Browser")
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.fetchStatus()
            }
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchStatus()
                }
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if let summary = viewModel.summary {
                // Section: Overall Status Banner Card
                Section {
                    overallBanner(summary: summary)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                // Section: Core Services Health
                if let components = summary.components, !components.isEmpty {
                    Section(header: Text("Services & Infrastructure (\(filteredComponents(components).count))")) {
                        ForEach(filteredComponents(components)) { comp in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(statusColor(comp.status))
                                    .frame(width: 8, height: 8)
                                
                                Text(comp.name)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Text(statusLabel(comp.status))
                                    .font(.caption)
                                    .foregroundStyle(statusColor(comp.status))
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                // Section: Unresolved Incidents
                if let incidents = summary.incidents, !incidents.isEmpty {
                    Section(header: Text("Active Incidents (\(incidents.count))")) {
                        ForEach(incidents) { inc in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(inc.name)
                                        .font(.body.weight(.medium))
                                    Spacer()
                                    CloudnsBadge(.warning(inc.status.capitalized), isCompact: true)
                                }
                                
                                if let updated = inc.updatedAt {
                                    Text(DateFormatters.formatISO8601ToDisplay(updated, style: DateFormatters.mediumDateTime))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 3)
                        }
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
            } else if viewModel.hasFetchedData, let err = viewModel.errorMessage, viewModel.summary == nil {
                StateOverlayView(
                    state: .error(
                        message: LocalizedStringKey(err),
                        retryAction: { Task { await viewModel.fetchStatus() } }
                    )
                )
            }
        }
    }
    
    private func overallBanner(summary: CFStatusSummary) -> some View {
        let isOperational = summary.status?.indicator == "none"
        let bgColor = isOperational ? Color.green : Color.orange
        
        return HStack(spacing: 16) {
            Image(systemName: isOperational ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.status?.description ?? "All Systems Operational")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                
                Text("Cloudflare Edge Network & Global Data Centers")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
        }
        .padding(18)
        .background(bgColor.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: bgColor.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func filteredComponents(_ comps: [CFComponentItem]) -> [CFComponentItem] {
        comps.filter {
            !$0.name.lowercased().contains("visit") &&
            !$0.name.lowercased().contains("subscribe")
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "operational": return .green
        case "degraded_performance": return .orange
        case "partial_outage": return .orange
        case "major_outage": return .red
        default: return .green
        }
    }
    
    private func statusLabel(_ status: String) -> String {
        switch status.lowercased() {
        case "operational": return "Operational"
        case "degraded_performance": return "Degraded"
        case "partial_outage": return "Partial Outage"
        case "major_outage": return "Major Outage"
        default: return status.capitalized
        }
    }
}
