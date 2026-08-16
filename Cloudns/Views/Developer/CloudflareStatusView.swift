import SwiftUI
import Combine

// MARK: - Models for Cloudflare Statuspage

struct CFStatusSummary: Codable {
    let page: CFStatusPage?
    let status: CFOverallStatus?
    let components: [CFComponentItem]?
    let incidents: [CFIncidentItem]?
}

struct CFStatusPage: Codable {
    let id: String?
    let name: String?
    let url: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, url
        case updatedAt = "updated_at"
    }
}

struct CFOverallStatus: Codable {
    let indicator: String // none, minor, major, critical
    let description: String
}

struct CFComponentItem: Codable, Identifiable {
    let id: String
    let name: String
    let status: String // operational, degraded_performance, partial_outage, major_outage
    let description: String?
    let position: Int?
    
    init(id: String, name: String, status: String = "operational", description: String? = nil, position: Int? = 1) {
        self.id = id
        self.name = name
        self.status = status
        self.description = description
        self.position = position
    }
    
    static let placeholders: [CFComponentItem] = [
        CFComponentItem(id: "1", name: "Authoritative DNS"),
        CFComponentItem(id: "2", name: "Cloudflare Dashboard"),
        CFComponentItem(id: "3", name: "Cloudflare Workers"),
        CFComponentItem(id: "4", name: "Cloudflare Pages"),
        CFComponentItem(id: "5", name: "R2 Object Storage"),
        CFComponentItem(id: "6", name: "D1 SQL Database")
    ]
}

struct CFIncidentItem: Codable, Identifiable {
    let id: String
    let name: String
    let status: String // resolved, monitoring, identified, investigating
    let impact: String // none, minor, major, critical
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, status, impact
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - ViewModel

@MainActor
class CloudflareStatusViewModel: ObservableObject {
    @Published var summary: CFStatusSummary?
    @Published var isLoading = false
    @Published var hasFetchedData = false
    @Published var errorMessage: String?
    
    func fetchStatus() async {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "https://www.cloudflarestatus.com/api/v2/summary.json") else {
            errorMessage = "Invalid status URL"
            isLoading = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw APIError.invalidResponse
            }
            let decoded = try JSONDecoder().decode(CFStatusSummary.self, from: data)
            self.summary = decoded
            self.hasFetchedData = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - View

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
            if !viewModel.hasFetchedData {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("All Systems Operational")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("Cloudflare Edge Network & Global Data Centers")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        Spacer()
                    }
                    .padding(18)
                    .background(Color.green.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                Section(header: Text("Services & Infrastructure")) {
                    ForEach(CFComponentItem.placeholders) { comp in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            
                            Text(comp.name)
                                .font(.body)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Text("Operational")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .skeletonLoading(true)
            } else if let summary = viewModel.summary {
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
                
                // Section: Active / Recent Incidents
                if let incidents = summary.incidents, !incidents.isEmpty {
                    Section(header: Text("Recent Incidents (\(incidents.count))")) {
                        ForEach(incidents.prefix(5)) { inc in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(inc.name)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text(inc.status.capitalized)
                                        .font(.caption2.weight(.medium))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.12))
                                        .foregroundStyle(.orange)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                
                                if let updated = inc.updatedAt {
                                    Text(String(updated.prefix(19)).replacingOccurrences(of: "T", with: " "))
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
        .overlay {
            if viewModel.hasFetchedData, let err = viewModel.errorMessage, viewModel.summary == nil {
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
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
