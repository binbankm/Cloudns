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
    
    private var isHourlyData: Bool {
        if let first = viewModel.dataPoints.first?.dimensions {
            if let dt = first.datetime, dt.contains("T") {
                return true
            }
            if first.date != nil {
                return false
            }
        }
        return viewModel.loadedDays == 1
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 1. Unified Header & Time Range Picker Bar
                headerBar
                
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    Group {
                        metricsGrid
                            .skeletonLoading(true)
                        
                        requestsLineChartCard
                            .skeletonLoading(true)
                        
                        bandwidthBarChartCard
                            .skeletonLoading(true)
                    }
                } else if viewModel.hasFetchedData && viewModel.dataPoints.isEmpty {
                    if let errorMessage = viewModel.errorMessage {
                        StateOverlayView(
                            state: .error(
                                message: LocalizedStringKey(errorMessage),
                                retryAction: {
                                    Task { await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange) }
                                }
                            )
                        )
                        .padding(.vertical, 30)
                    } else {
                        StateOverlayView(
                            state: .empty(
                                icon: "chart.xyaxis.line",
                                title: "No Traffic Data",
                                message: "No HTTP requests recorded for \(zoneName) in the selected time range."
                            )
                        )
                        .padding(.vertical, 30)
                    }
                } else {
                    Group {
                        // 2. 4 Key Metrics Cards Grid
                        metricsGrid
                        
                        // 3. Requests 折线图 (Line Chart with Gradient Area)
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
                    .opacity(viewModel.isLoading ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .centerConstrainedWidth(maxWidth: 840)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Zone Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange, isRefresh: true)
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange)
            }
        }
    }
    
    // MARK: - 1. Header Bar
    private var headerBar: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "globe")
                .foregroundStyle(.blue)
                .font(.title3)
            
            Text(zoneName)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Spacer(minLength: 6)
            
            Picker("Range", selection: $timeRange) {
                Text("24H").tag(1)
                Text("7D").tag(7)
                Text("30D").tag(30)
            }
            .pickerStyle(.segmented)
            .frame(width: 145)
            .onChange(of: timeRange) { newValue in
                HapticManager.impact(.light)
                Task {
                    await viewModel.fetchAnalytics(zoneTag: zoneId, days: newValue)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - 2. Key Metrics Grid
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard(
                title: "Total Requests",
                value: formatNumber(viewModel.totalRequests),
                icon: "globe",
                color: .blue,
                badge: "\(viewModel.formatBytes(viewModel.totalBandwidthBytes)) Data Transferred"
            )
            
            metricCard(
                title: "Cached Requests",
                value: formatNumber(viewModel.totalCachedRequests),
                icon: "bolt.fill",
                color: .orange,
                badge: "\(String(format: "%.1f%%", viewModel.cachedRatio * 100)) Cache Rate"
            )
            
            metricCard(
                title: "Cache Hit Ratio",
                value: String(format: "%.1f%%", viewModel.cachedRatio * 100),
                icon: "chart.pie.fill",
                color: .green,
                badge: "Edge Served"
            )
            
            metricCard(
                title: "Data Transferred",
                value: viewModel.formatBytes(viewModel.totalBandwidthBytes),
                icon: "arrow.up.arrow.down",
                color: .purple,
                badge: "\(viewModel.formatBytes(viewModel.totalCachedBandwidthBytes)) Saved by Cache"
            )
        }
    }
    
    private func metricCard(title: LocalizedStringKey, value: String, icon: String, color: Color, badge: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 22, height: 22)
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(color)
                }
                .accessibilityHidden(true)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Spacer()
            }
            
            Spacer(minLength: 2)
            
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            Spacer(minLength: 2)
            
            Text(badge)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 102, maxHeight: 102, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - 3. Requests 折线图 (Line Chart)
    private var requestsLineChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                Text("Requests Traffic")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("Total vs Cached")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Chart {
                ForEach(viewModel.dataPoints) { point in
                    let ptDate = dateFromString(point.dimensions.datetime ?? point.dimensions.date ?? "")
                    
                    AreaMark(
                        x: .value("Date", ptDate),
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
                        x: .value("Date", ptDate),
                        y: .value("Requests", point.sum.requests)
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                }
            }
            .id("requests_chart_\(viewModel.loadedDays)")
            .animation(.easeInOut(duration: 0.25), value: viewModel.dataPoints)
            .frame(height: 230)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    if isHourlyData {
                        AxisValueLabel(format: .dateTime.hour(), collisionResolution: .greedy)
                            .font(.caption2)
                    } else {
                        AxisValueLabel(format: .dateTime.month().day(), collisionResolution: .greedy)
                            .font(.caption2)
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
                Text("Bandwidth")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("Data Transferred over Time")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Chart {
                ForEach(viewModel.dataPoints) { point in
                    let ptDate = dateFromString(point.dimensions.datetime ?? point.dimensions.date ?? "")
                    BarMark(
                        x: .value("Date", ptDate),
                        y: .value("Bytes", point.sum.bytes)
                    )
                    .foregroundStyle(Color.purple)
                    .cornerRadius(4)
                }
            }
            .id("bandwidth_chart_\(viewModel.loadedDays)")
            .animation(.easeInOut(duration: 0.25), value: viewModel.dataPoints)
            .frame(height: 220)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    if isHourlyData {
                        AxisValueLabel(format: .dateTime.hour(), collisionResolution: .greedy)
                            .font(.caption2)
                    } else {
                        AxisValueLabel(format: .dateTime.month().day(), collisionResolution: .greedy)
                            .font(.caption2)
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
    
    // MARK: - 5. Traffic by Country Map
    private var trafficMapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map.fill")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                Text("Traffic by Country / Region")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("Top Traffic Origins")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
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
        guard let maxRequests = viewModel.mapDataPoints.map({ $0.requestsCount }).max(), maxRequests > 0 else { return [] }
        return viewModel.mapDataPoints.compactMap { point in
            guard let code = point.dimensions.clientCountryName,
                  let coordinate = CountryCoordinates.map[code] else { return nil }
            let requests = point.requestsCount
            let ratio = Double(requests) / Double(maxRequests)
            let size = 12.0
            return MapAnnotationItem(countryCode: code, coordinate: coordinate, size: size, requests: requests, ratio: ratio)
        }
    }
    
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 30, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 120)
    )
    @State private var selectedCountry: String?
    
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
            Label("Edge Caching Savings", systemImage: "sparkles")
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
                Text("Edge Cache Ratio")
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
