import SwiftUI

// MARK: - ZonesListView

struct ZonesListView: View {
    @StateObject private var viewModel = ZonesViewModel()
    @AppStorage(AppStorageKey.isLoggedIn) private var isLoggedIn = true
    @State private var searchText = ""
    @State private var zoneToDelete: Zone?
    @State private var showingDeleteAlert = false
    @State private var showAddZoneSheet = false
    
    private var displayedZones: [Zone] {
        viewModel.filteredZones(query: searchText)
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !displayedZones.isEmpty {
                    zonesSection
                }
            }
            .listStyle(.insetGrouped)
            .scrollDismissesKeyboard(.interactively)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search Domains"
            )
            .navigationTitle("My Domains")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.fetchZones(isRefresh: true)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.addZoneError = nil
                        showAddZoneSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Domain")
                }
            }
            .sheet(isPresented: $showAddZoneSheet) {
                AddZoneView(viewModel: viewModel, isPresented: $showAddZoneSheet)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .higToast()
            }
            .overlay {
                emptyStateOverlay
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoneDeleted)) { _ in
            Task { await viewModel.fetchZones(isRefresh: true) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoneUpdated)) { _ in
            Task { await viewModel.fetchZones(isRefresh: true) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .accountSwitched)) { _ in
            viewModel.resetState()
            Task { await viewModel.fetchZones(isRefresh: true) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .localCachePurged)) { _ in
            viewModel.resetState()
            Task { await viewModel.fetchZones(isRefresh: true) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .appWillEnterForeground)) { _ in
            if viewModel.isStale {
                Task { await viewModel.fetchZones(isRefresh: true) }
            }
        }
        .onAppear {
            if !viewModel.zones.isEmpty && viewModel.sparklines.isEmpty {
                viewModel.fetchBatchSparklines(for: viewModel.zones)
            }
        }
        .task {
            if !viewModel.hasFetchedData || viewModel.isStale {
                await viewModel.fetchZones()
            }
        }
        .confirmationDialog(
            "Delete Domain",
            isPresented: $showingDeleteAlert,
            titleVisibility: .visible,
            presenting: zoneToDelete
        ) { zone in
            Button("Delete \(zone.name)", role: .destructive) {
                HIGFeedback.impact(.medium)
                Task {
                    await viewModel.deleteZone(zoneId: zone.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { zone in
            Text("Are you sure you want to delete \(zone.name) from your Cloudflare account? This action cannot be undone.")
        }
    }
    
    // MARK: - Subviews
    
    private var zonesSection: some View {
        Section {
            ForEach(displayedZones) { zone in
                NavigationLink(destination: ZoneDetailView(zone: zone)) {
                    ZoneRowView(zone: zone, sparkline: viewModel.sparklines[zone.id])
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        HIGFeedback.impact(.medium)
                        zoneToDelete = zone
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            if viewModel.canLoadMore && searchText.isEmpty && viewModel.hasFetchedData {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .onAppear {
                    Task { await viewModel.fetchZones(isRefresh: false) }
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateOverlay: some View {
        if !viewModel.hasFetchedData && viewModel.isLoading {
            HIGContentState(.loading(message: "Loading Domains…"))
        } else if let errorMessage = viewModel.errorMessage, viewModel.zones.isEmpty {
            HIGContentState(
                .error(
                    message: LocalizedStringKey(errorMessage),
                    retryAction: {
                        Task { await viewModel.fetchZones(isRefresh: true) }
                    }
                )
            )
        } else if viewModel.hasFetchedData && viewModel.zones.isEmpty {
            HIGContentState(
                .empty(
                    title: "No Domains Found",
                    systemImage: "globe",
                    description: "Add your first domain to start managing DNS records and Cloudflare edge services.",
                    actionTitle: "Add Domain",
                    action: { showAddZoneSheet = true }
                )
            )
        } else if viewModel.hasFetchedData && displayedZones.isEmpty && !searchText.isEmpty {
            HIGContentState(.search(query: searchText))
        }
    }
}

// MARK: - ZoneRowView (Inlined & Cohesive)

struct ZoneRowView: View {
    let zone: Zone
    let sparkline: ZoneSparklineCache?
    
    init(zone: Zone, sparkline: ZoneSparklineCache? = nil) {
        self.zone = zone
        self.sparkline = sparkline
    }
    
    private var initialChar: String {
        guard let first = zone.name.first else { return "D" }
        return String(first).uppercased()
    }
    
    private var avatarColor: Color {
        let palette: [Color] = [.blue, .indigo, .purple, .teal, .mint, .cyan, .orange, .pink]
        let hash = abs(zone.name.hashValue)
        return palette[hash % palette.count]
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.14))
                    .frame(width: 36, height: 36)
                Text(initialChar)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(avatarColor)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: zone.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if zone.paused || (zone.developmentMode ?? 0) > 0 {
                    HStack(spacing: 5) {
                        if zone.paused {
                            Text("Paused")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Color.red.opacity(0.15))
                                .foregroundStyle(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                        
                        if (zone.developmentMode ?? 0) > 0 {
                            Text("Dev Mode")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Color.orange.opacity(0.15))
                                .foregroundStyle(.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                    }
                }
            }
            
            Spacer(minLength: 8)
            
            ZoneRowSparklineView(zoneId: zone.id, cached: sparkline)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - ZoneTrafficSparklineView (Inlined & Cohesive)

public struct ZoneTrafficSparklineView: View {
    let data: [Double]
    let lineColor: Color
    let lineWidth: CGFloat
    let showGradientFill: Bool
    
    public init(
        data: [Double],
        lineColor: Color = .blue,
        lineWidth: CGFloat = 1.8,
        showGradientFill: Bool = true
    ) {
        self.data = data
        self.lineColor = lineColor
        self.lineWidth = lineWidth
        self.showGradientFill = showGradientFill
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let width = max(1, proxy.size.width)
            let height = max(1, proxy.size.height)
            let validValues = data.map { max(0, $0) }
            let points = normalizedPoints(for: validValues, in: CGSize(width: width, height: height))
            
            ZStack {
                if showGradientFill && points.count > 1 {
                    path(for: points, closedToBottom: true, height: height, width: width)
                        .fill(
                            LinearGradient(
                                colors: [lineColor.opacity(0.35), lineColor.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                if points.count > 1 {
                    path(for: points, closedToBottom: false, height: height, width: width)
                        .stroke(
                            LinearGradient(
                                colors: [lineColor.opacity(0.65), lineColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: lineColor.opacity(0.35), radius: 2.5, x: 0, y: 1)
                    
                    if let last = points.last {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 3.5, height: 3.5)
                            .shadow(color: lineColor, radius: 2)
                            .position(last)
                    }
                } else {
                    Path { p in
                        p.move(to: CGPoint(x: 2, y: height * 0.75))
                        p.addLine(to: CGPoint(x: width - 2, y: height * 0.75))
                    }
                    .stroke(lineColor.opacity(0.22), style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
                }
            }
            .clipped()
        }
    }
    
    private func normalizedPoints(for values: [Double], in size: CGSize) -> [CGPoint] {
        guard values.count > 1 else { return [] }
        
        let maxVal = values.max() ?? 1.0
        let minVal = values.min() ?? 0.0
        let range = max(maxVal - minVal, 1.0)
        
        let horizontalPadding: CGFloat = 2.0
        let usableWidth = max(1, size.width - horizontalPadding * 2)
        let stepX = usableWidth / CGFloat(values.count - 1)
        
        let usableHeight = size.height * 0.70
        let offsetY = size.height * 0.15
        
        return values.enumerated().map { index, val in
            let normY = (val - minVal) / range
            let y = size.height - (CGFloat(normY) * usableHeight + offsetY)
            let x = horizontalPadding + CGFloat(index) * stepX
            return CGPoint(x: x, y: y)
        }
    }
    
    private func path(for points: [CGPoint], closedToBottom: Bool, height: CGFloat, width: CGFloat) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        
        path.move(to: points[0])
        
        for i in 1..<points.count {
            let p0 = points[i - 1]
            let p1 = points[i]
            let midPoint = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
            let controlPoint1 = CGPoint(x: (midPoint.x + p0.x) / 2, y: p0.y)
            let controlPoint2 = CGPoint(x: (midPoint.x + p1.x) / 2, y: p1.y)
            
            path.addCurve(to: midPoint, control1: controlPoint1, control2: CGPoint(x: midPoint.x, y: p0.y))
            path.addCurve(to: p1, control1: CGPoint(x: midPoint.x, y: p1.y), control2: controlPoint2)
        }
        
        if closedToBottom {
            path.addLine(to: CGPoint(x: points.last?.x ?? width, y: height))
            path.addLine(to: CGPoint(x: points[0].x, y: height))
            path.closeSubpath()
        }
        
        return path
    }
}

// MARK: - ZoneRowSparklineView (Inlined & Cohesive)

public struct ZoneRowSparklineView: View {
    let zoneId: String
    let cached: ZoneSparklineCache?
    
    public init(zoneId: String, cached: ZoneSparklineCache? = nil) {
        self.zoneId = zoneId
        self.cached = cached
    }
    
    public var body: some View {
        let points = cached?.points ?? []
        let total = cached?.totalRequests ?? 0
        
        HStack(spacing: 5) {
                ZoneTrafficSparklineView(
                    data: points,
                    lineColor: sparklineColor(total: total),
                    lineWidth: 1.5
                )
                .frame(width: 44, height: 22)
                
                if total > 0 {
                    Text(formatMetric(total))
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .accessibilityHidden(true)
    }
    
    private func sparklineColor(total: Int) -> Color {
        if total > 10_000 {
            return .orange
        } else if total > 100 {
            return .blue
        } else {
            return .teal
        }
    }
    
    private func formatMetric(_ value: Int) -> String {
        if value >= 1_000_000 {
            return "\((Double(value) / 1_000_000.0).formatted(.number.precision(.fractionLength(1))))M"
        } else if value >= 1_000 {
            return "\((Double(value) / 1_000.0).formatted(.number.precision(.fractionLength(1))))K"
        } else {
            return value.formatted(.number)
        }
    }
}

// MARK: - ZoneSparklineCache

public struct ZoneSparklineCache: Codable, Sendable {
    public let points: [Double]
    public let totalRequests: Int
    
    public init(points: [Double], totalRequests: Int) {
        self.points = points
        self.totalRequests = totalRequests
    }
}
