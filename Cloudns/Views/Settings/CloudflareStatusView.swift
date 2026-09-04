import SwiftUI

// MARK: - CloudflareStatusView
// Apple HIG Compliant Cloudflare System Status & PoP Health (iOS 16.0+)

struct CloudflareStatusView: View {
    @StateObject private var viewModel = CloudflareStatusViewModel()
    @State private var selectedTab: StatusFilterTab = .issues
    @State private var searchText: String = ""
    
    enum StatusFilterTab: Int, CaseIterable, Identifiable {
        case issues = 0
        case services = 1
        case pops = 2
        
        var id: Int { rawValue }
        
        var titleKey: LocalizedStringKey {
            switch self {
            case .issues: return "Issues & Outages"
            case .services: return "Core Services"
            case .pops: return "Data Centers"
            }
        }
    }
    
    private var allComponents: [CFComponentItem] {
        viewModel.summary?.components ?? []
    }
    
    private var issuesComponents: [CFComponentItem] {
        allComponents.filter { $0.status.lowercased() != "operational" }
    }
    
    private var servicesComponents: [CFComponentItem] {
        allComponents.filter { isCoreService($0.name) }
    }
    
    private var popsComponents: [CFComponentItem] {
        allComponents.filter { isDataCenter($0.name) }
    }
    
    private var displayedComponents: [CFComponentItem] {
        let baseList: [CFComponentItem]
        switch selectedTab {
        case .issues:
            baseList = issuesComponents
        case .services:
            baseList = servicesComponents
        case .pops:
            baseList = popsComponents
        }
        
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            return baseList
        }
        
        return baseList.filter {
            $0.name.lowercased().contains(q) ||
            (extractIATA($0.name)?.lowercased().contains(q) ?? false)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Segmented Picker Header
            Picker("Category", selection: $selectedTab) {
                Text(viewModel.hasFetchedData ? "Issues (\(issuesComponents.count))" : "Issues").tag(StatusFilterTab.issues)
                Text(viewModel.hasFetchedData ? "Services (\(servicesComponents.count))" : "Services").tag(StatusFilterTab.services)
                Text(viewModel.hasFetchedData ? "PoPs (\(popsComponents.count))" : "PoPs").tag(StatusFilterTab.pops)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(uiColor: .systemGroupedBackground))
            .onChange(of: selectedTab) { _ in
                HapticManager.selection()
            }
            
            contentView
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search Services or PoPs"
        )
        .scrollDismissesKeyboard(.interactively)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("System Status")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
                // Default to services tab if 0 active issues
                if let summary = viewModel.summary, let comps = summary.components {
                    let issueCount = comps.filter { $0.status.lowercased() != "operational" }.count
                    if issueCount == 0 && (summary.incidents?.isEmpty ?? true) {
                        selectedTab = .services
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            if let summary = viewModel.summary {
                // MARK: - Overall Banner
                if searchText.isEmpty {
                    Section {
                        overallBanner(summary: summary)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                
                // MARK: - Active Incidents (if any)
                if let incidents = summary.incidents, !incidents.isEmpty, searchText.isEmpty {
                    Section(header: Text("Official Incidents (\(incidents.count))")) {
                        ForEach(incidents) { inc in
                            incidentRow(inc)
                        }
                    }
                }
                
                // MARK: - Displayed Component List
                if !displayedComponents.isEmpty {
                    Section(header: Text(sectionHeaderTitle(tab: selectedTab, count: displayedComponents.count))) {
                        ForEach(displayedComponents) { comp in
                            componentRow(comp)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listState(
            isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
            loadingMessage: "Loading System Status…",
            error: (viewModel.summary == nil) ? viewModel.errorMessage : nil,
            isEmpty: viewModel.hasFetchedData && displayedComponents.isEmpty && searchText.isEmpty && selectedTab == .issues,
            empty: .init(
                title: "All Systems Operational",
                systemImage: "checkmark.seal.fill",
                description: "No degraded services or active outages detected right now."
            ),
            searchQuery: (viewModel.hasFetchedData && displayedComponents.isEmpty && !searchText.isEmpty) ? searchText : nil,
            onRetry: {
                Task { await viewModel.fetchStatus() }
            }
        )
    }
    
    // MARK: - Component Row View
    @ViewBuilder
    private func componentRow(_ comp: CFComponentItem) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor(comp.status))
                .frame(width: 8, height: 8)
                .shadow(color: statusColor(comp.status).opacity(comp.status.lowercased() == "operational" ? 0 : 0.4), radius: 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(comp.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                if let iata = extractIATA(comp.name) {
                    Text(iata)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            statusBadge(comp.status)
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Incident Row View
    @ViewBuilder
    private func incidentRow(_ inc: CFIncidentItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(inc.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text(inc.status.capitalized)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.14))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            }
            
            if let updated = inc.updatedAt, let date = DateFormatters.parseISO8601(updated) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Updated: \(date.displayFormatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Overall Banner Card
    private func overallBanner(summary: CFStatusSummary) -> some View {
        let isOperational = summary.status?.indicator == "none"
        let bgColor = isOperational ? Color.green : Color.orange
        
        return HStack(spacing: 12) {
            Image(systemName: isOperational ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.status?.description ?? "All Systems Operational")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                
                Text(isOperational ? "Cloudflare Global Network & Edge Services Normal" : "Some services or edge data centers are degraded")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            
            Spacer()
        }
        .padding(16)
        .background(bgColor.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: bgColor.opacity(0.25), radius: 6, x: 0, y: 3)
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }
    
    // MARK: - Helpers
    private func isDataCenter(_ name: String) -> Bool {
        name.contains(" - (") || (name.contains(" (") && name.hasSuffix(")"))
    }
    
    private func isCoreService(_ name: String) -> Bool {
        !isDataCenter(name)
    }
    
    private func extractIATA(_ name: String) -> String? {
        if let match = name.range(of: #"\([A-Z]{3,4}\)"#, options: .regularExpression) {
            return String(name[match])
        }
        return nil
    }
    
    private func sectionHeaderTitle(tab: StatusFilterTab, count: Int) -> LocalizedStringKey {
        switch tab {
        case .issues:
            return "Active Issues & Maintenance (\(count))"
        case .services:
            return "Core Services & APIs (\(count))"
        case .pops:
            return "Global Edge PoP Locations (\(count))"
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "operational": return .green
        case "under_maintenance": return .blue
        case "degraded_performance", "partial_outage": return .orange
        case "major_outage": return .red
        default: return .green
        }
    }
    
    @ViewBuilder
    private func statusBadge(_ status: String) -> some View {
        let text = status.replacingOccurrences(of: "_", with: " ").capitalized
        let color = statusColor(status)
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
