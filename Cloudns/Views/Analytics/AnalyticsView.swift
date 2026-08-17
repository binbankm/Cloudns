import SwiftUI
import Charts
import MapKit

public struct AnalyticsView: View {
    public let zoneId: String
    public let zoneName: String
    
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var timeRange: Int = 30
    
    public init(zoneId: String, zoneName: String) {
        self.zoneId = zoneId
        self.zoneName = zoneName
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. Unified Header & Time Range Picker Bar
                headerBar
                
                if viewModel.hasFetchedData && !viewModel.dataPoints.isEmpty {
                    // 2. 4 Key Metrics Cards Grid
                    metricsGrid
                    
                    // 3. Requests 折线图 (Line Chart with Points & Gradient Area)
                    requestsLineChartCard
                    
                    // 4. Bandwidth 柱状图 (Bar Chart)
                    bandwidthBarChartCard
                    
                    // 5. Traffic by Country Map Section
                    if !viewModel.mapDataPoints.isEmpty {
                        trafficMapCard
                    }
                    
                    // 6. CDN Origin Savings Summary Card
                    insightsCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .centerConstrainedWidth(maxWidth: 840)
        }
        .background(Color(.systemGroupedBackground))
        .overlay {
            if !viewModel.hasFetchedData && viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.hasFetchedData {
                if let errorMessage = viewModel.errorMessage, viewModel.dataPoints.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: {
                                Task { await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange) }
                            }
                        )
                    )
                } else if viewModel.dataPoints.isEmpty {
                    StateOverlayView(
                        state: .empty(
                            icon: "chart.xyaxis.line",
                            title: "No Analytics Data",
                            message: "Traffic metrics for the selected time range are currently unavailable."
                        )
                    )
                }
            }
        }
        .navigationTitle("Zone Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange)
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange)
            }
        }
    }
    
    // MARK: - 1. Header Bar
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: "globe.americas.fill")
                        .foregroundStyle(.blue)
                        .font(.headline)
                    Text(zoneName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                Text("Zone CDN & Traffic")
                    .font(.caption2.monospaced())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.12))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            Picker("Range", selection: $timeRange) {
                Text("24H").tag(1)
                Text("7D").tag(7)
                Text("30D").tag(30)
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
            .onChange(of: timeRange) { newValue in
                HapticManager.impact(.light)
                Task {
                    await viewModel.fetchAnalytics(zoneTag: zoneId, days: newValue)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    // MARK: - 2. Key Metrics Grid
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard(
                title: "Total Requests",
                value: formatNumber(viewModel.totalRequests),
                icon: "globe",
                color: .blue,
                badge: "\(viewModel.formatBytes(viewModel.totalBandwidthBytes)) transferred"
            )
            
            metricCard(
                title: "Cached Requests",
                value: formatNumber(viewModel.totalCachedRequests),
                icon: "bolt.fill",
                color: .orange,
                badge: String(format: "%.1f%% Cache Hit", viewModel.cachedRatio * 100)
            )
            
            metricCard(
                title: "Cache Efficiency",
                value: String(format: "%.1f%%", viewModel.cachedRatio * 100),
                icon: "chart.pie.fill",
                color: .green,
                badge: "Edge Optimized"
            )
            
            metricCard(
                title: "Total Bandwidth",
                value: viewModel.formatBytes(viewModel.totalBandwidthBytes),
                icon: "arrow.up.arrow.down",
                color: .purple,
                badge: "\(viewModel.formatBytes(viewModel.totalCachedBandwidthBytes)) saved"
            )
        }
    }
    
    private func metricCard(title: String, value: String, icon: String, color: Color, badge: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
            
            Text(badge)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.12))
                .foregroundStyle(color)
                .clipShape(Capsule())
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    // MARK: - 3. Requests 折线图 (Line Chart)
    private var requestsLineChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                Text("Requests Traffic Trend (折线图)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("Requests/Time")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Chart {
                ForEach(viewModel.dataPoints) { point in
                    AreaMark(
                        x: .value("Date", dateFromString(point.dimensions.datetime ?? point.dimensions.date ?? "")),
                        y: .value("Requests", point.sum.requests)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.35), Color.blue.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Date", dateFromString(point.dimensions.datetime ?? point.dimensions.date ?? "")),
                        y: .value("Requests", point.sum.requests)
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .symbol(Circle().strokeBorder(lineWidth: 1.5))
                    .symbolSize(32)
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 230)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    if timeRange == 1 {
                        AxisValueLabel(format: .dateTime.hour(), centered: true)
                    } else {
                        AxisValueLabel(format: .dateTime.month().day(), centered: true)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    if let count = value.as(Int.self) {
                        AxisValueLabel {
                            Text(formatNumber(count))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - 4. Bandwidth 柱状图 (Bar Chart)
    private var bandwidthBarChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.subheadline)
                    .foregroundStyle(.purple)
                Text("Bandwidth Transfer Volume (柱状图)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("Bytes/Time")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Chart {
                ForEach(viewModel.dataPoints) { point in
                    BarMark(
                        x: .value("Date", dateFromString(point.dimensions.datetime ?? point.dimensions.date ?? "")),
                        y: .value("Bytes", point.sum.bytes)
                    )
                    .foregroundStyle(Color.purple)
                    .cornerRadius(4)
                }
            }
            .frame(height: 220)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    if timeRange == 1 {
                        AxisValueLabel(format: .dateTime.hour(), centered: true)
                    } else {
                        AxisValueLabel(format: .dateTime.month().day(), centered: true)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    if let bytes = value.as(Int.self) {
                        AxisValueLabel {
                            Text(viewModel.formatBytes(bytes))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func dateFromString(_ dateString: String) -> Date {
        DateFormatters.parseChartDate(dateString)
    }
    
    // MARK: - 5. Map Component Card
    private var trafficMapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Global Traffic by Country", systemImage: "map.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.blue)
            
            trafficMapView
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    struct MapAnnotationItem: Identifiable {
        let id = UUID()
        let countryCode: String
        let coordinate: CLLocationCoordinate2D
        let size: CGFloat
        let requests: Int
        let ratio: Double
    }
    
    private var mapAnnotations: [MapAnnotationItem] {
        guard let maxRequests = viewModel.mapDataPoints.map({ $0.count }).max(), maxRequests > 0 else { return [] }
        return viewModel.mapDataPoints.compactMap { point in
            guard let code = point.dimensions.clientCountryName,
                  let coordinate = CountryCoordinates.map[code] else { return nil }
            let ratio = Double(point.count) / Double(maxRequests)
            let size = 12.0
            return MapAnnotationItem(countryCode: code, coordinate: coordinate, size: size, requests: point.count, ratio: ratio)
        }
    }
    
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 30, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 120)
    )
    @State private var selectedCountry: String? = nil
    
    private var trafficMapView: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $mapRegion, annotationItems: mapAnnotations) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    Button {
                        HapticManager.impact(.light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedCountry = item.countryCode
                        }
                    } label: {
                        PulsingAnnotationView(item: item, isSelected: selectedCountry == item.countryCode)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Button {
                withAnimation(.easeInOut) { selectedCountry = nil }
            } label: {
                Color.white.opacity(0.001)
            }
            .buttonStyle(.plain)
            .allowsHitTesting(selectedCountry != nil)
            
            if let selected = selectedCountry,
               let item = mapAnnotations.first(where: { $0.countryCode == selected }) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Country: \(item.countryCode)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("\(formatNumber(item.requests)) Requests")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Button {
                        withAnimation(.easeInOut) { selectedCountry = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground).opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - 6. Performance Insights Card
    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("CDN Cache & Origin Savings", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.blue)
            
            HStack {
                Text("Origin Bandwidth Saved")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.formatBytes(viewModel.totalCachedBandwidthBytes))
                    .font(.caption.weight(.semibold).monospacedDigit())
            }
            
            Divider()
            
            HStack {
                Text("Edge Hit Ratio")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.1f%%", viewModel.cachedRatio * 100))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(viewModel.cachedRatio > 0.5 ? .green : .orange)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private func formatNumber(_ num: Int) -> String {
        if num < 1000 { return "\(num)" }
        let k = Double(num) / 1000.0
        if k < 1000 { return String(format: "%.1fK", k) }
        let m = k / 1000.0
        return String(format: "%.2fM", m)
    }
}

public struct PulsingAnnotationView: View {
    let item: AnalyticsView.MapAnnotationItem
    let isSelected: Bool
    @State private var isPulsing = false
    
    private var heatColor: Color {
        switch item.ratio {
        case 0.7...: return .red
        case 0.3..<0.7: return .orange
        case 0.1..<0.3: return .yellow
        default: return .cyan
        }
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .stroke(heatColor, lineWidth: 2)
                .frame(width: item.size, height: item.size)
                .scaleEffect(isPulsing ? 2.5 : 1.0)
                .opacity(isPulsing ? 0.0 : 0.8)
            
            Circle()
                .fill(heatColor)
                .frame(width: item.size, height: item.size)
                .overlay(Circle().stroke(Color.white, lineWidth: isSelected ? 2.5 : 0.5))
                .shadow(color: heatColor.opacity(0.6), radius: isSelected ? 10 : 3, x: 0, y: 0)
                .scaleEffect(isSelected ? 1.3 : 1.0)
        }
        .onAppear {
            withAnimation(Animation.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}
