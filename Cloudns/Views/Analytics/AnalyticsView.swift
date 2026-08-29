import SwiftUI
import Charts
import MapKit

// MARK: - AnalyticsView

struct AnalyticsView: View {
    let zoneId: String
    let zoneName: String
    
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var timeRange: Int = 1
    
    // Interactive Scrubbing States
    @State private var selectedPoint: AnalyticsDataPoint?
    @State private var selectedBandwidthPoint: AnalyticsDataPoint?
    
    init(zoneId: String, zoneName: String) {
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
    
    private var chartXRange: ClosedRange<Date> {
        if let first = viewModel.dataPoints.first,
           let last = viewModel.dataPoints.last {
            let start = dateFromString(first.dimensions.datetime ?? first.dimensions.date ?? "")
            let end = dateFromString(last.dimensions.datetime ?? last.dimensions.date ?? "")
            if start < end {
                return start...end
            } else if start == end {
                return start.addingTimeInterval(-1800)...end.addingTimeInterval(1800)
            }
        }
        let now = Date()
        return now...now.addingTimeInterval(3600)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. Unified Header & Time Range Picker Bar
            headerBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)
            
            if !viewModel.hasFetchedData && viewModel.isLoading {
                ScrollView {
                    VStack(spacing: 16) {
                        metricsGrid
                            .redacted(reason: .placeholder)
                        
                        requestsLineChartCard
                            .redacted(reason: .placeholder)
                        
                        bandwidthBarChartCard
                            .redacted(reason: .placeholder)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            } else if viewModel.hasFetchedData && viewModel.dataPoints.isEmpty {
                ScrollView {
                    VStack {
                        Spacer(minLength: 40)
                        if let errorMessage = viewModel.errorMessage {
                            StateOverlayView(
                                state: .error(
                                    message: LocalizedStringKey(errorMessage),
                                    retryAction: {
                                        Task { await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange) }
                                    }
                                )
                            )
                        } else {
                            StateOverlayView(
                                state: .empty(
                                    icon: "chart.xyaxis.line",
                                    title: "No Traffic Data",
                                    message: "No HTTP requests recorded for \(zoneName) in the selected time range."
                                )
                            )
                        }
                        Spacer(minLength: 80)
                    }
                    .frame(minHeight: 450)
                    .padding(.horizontal, 16)
                }
                .refreshable {
                    await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange, isRefresh: true)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // 2. 4 Key Metrics Cards Grid (Non-lazy Grid for rock-solid stability)
                        metricsGrid
                        
                        // 3. Requests 折线图 (Line Chart with Luminous Aurora & Interactive Scrubbing)
                        requestsLineChartCard
                        
                        // 4. Bandwidth 柱状图 (Bar Chart with Rounded Bars & Scrubbing)
                        bandwidthBarChartCard
                        
                        // 5. Traffic by Country Map Section
                        if !viewModel.mapDataPoints.isEmpty {
                            trafficMapCard
                        }
                        
                        // 6. CDN Origin Savings Summary Card
                        insightsCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                    .opacity(viewModel.isLoading ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
                }
                .refreshable {
                    await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange, isRefresh: true)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Zone Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(NotificationCenter.default.publisher(for: .localCachePurged)) { _ in
            viewModel.resetState()
            Task { await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange, isRefresh: true) }
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
                .minimumScaleFactor(0.7)
            
            Spacer(minLength: 4)
            
            Picker("Range", selection: $timeRange) {
                Text("24h").tag(1)
                Text("7d").tag(7)
                Text("30d").tag(30)
            }
            .pickerStyle(.segmented)
            .frame(width: 155)
            .onChange(of: timeRange) { newValue in
                HapticManager.impact(.light)
                selectedPoint = nil
                selectedBandwidthPoint = nil
                Task {
                    await viewModel.fetchAnalytics(zoneTag: zoneId, days: newValue)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - 2. Key Metrics Grid
    private var metricsGrid: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                metricCard(
                    title: "Total Requests",
                    value: formatNumber(viewModel.totalRequests),
                    icon: "globe",
                    color: .blue,
                    badge: "\(viewModel.formatBytes(viewModel.totalBandwidthBytes)) Transferred"
                )
                
                metricCard(
                    title: "Cached Requests",
                    value: formatNumber(viewModel.totalCachedRequests),
                    icon: "bolt.fill",
                    color: .orange,
                    badge: "\(String(format: "%.1f%%", viewModel.cachedRatio * 100)) Cache Rate"
                )
            }
            
            GridRow {
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
    }
    
    private func metricCard(title: LocalizedStringKey, value: String, icon: String, color: Color, badge: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 22, height: 22)
                    Image(systemName: icon)
                        .font(.caption2.weight(.semibold))
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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - 3. Requests 折线图 (Luminous Aurora + Interactive Live Scrubbing)
    private var requestsLineChartCard: some View {
        let maxReq = viewModel.dataPoints.map { $0.sum.requests }.max() ?? 10
        let yUpper = max(10.0, Double(maxReq) * 1.18)
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.blue)
                        Text("Requests Traffic")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(formatNumber(selectedPoint?.sum.requests ?? viewModel.totalRequests))
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(.primary)
                        Text(selectedPoint != nil ? "requests" : "total")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if let selected = selectedPoint {
                    let dateStr = formattedPointDate(selected)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                        Text(dateStr)
                            .font(.caption2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
                } else {
                    Text("Drag to Inspect")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(minHeight: 48)
            
            Chart {
                ForEach(viewModel.dataPoints) { point in
                    let ptDate = dateFromString(point.dimensions.datetime ?? point.dimensions.date ?? "")
                    
                    AreaMark(
                        x: .value("Date", ptDate),
                        y: .value("Requests", point.sum.requests)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.32), Color.blue.opacity(0.01)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)
                    
                    LineMark(
                        x: .value("Date", ptDate),
                        y: .value("Requests", point.sum.requests)
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                }
                
                if let selected = selectedPoint {
                    let selDate = dateFromString(selected.dimensions.datetime ?? selected.dimensions.date ?? "")
                    RuleMark(x: .value("Date", selDate))
                        .foregroundStyle(Color.blue.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                    
                    PointMark(
                        x: .value("Date", selDate),
                        y: .value("Requests", selected.sum.requests)
                    )
                    .symbol {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.25))
                                .frame(width: 16, height: 16)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .shadow(color: Color.blue, radius: 4)
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
            .id("requests_chart_\(viewModel.loadedDays)")
            .frame(height: 220)
            .chartPlotStyle { plot in
                plot.clipped()
            }
            .chartYScale(domain: 0...yUpper)
            .chartXScale(domain: chartXRange)
            .transaction { $0.animation = nil }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.secondary.opacity(0.2))
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
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    if let count = value.as(Int.self) {
                        AxisValueLabel {
                            Text(formatNumber(count))
                                .frame(width: 44, alignment: .trailing)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let origin = geo[proxy.plotAreaFrame].origin
                                    let locationX = value.location.x - origin.x
                                    guard locationX >= 0, locationX <= proxy.plotAreaSize.width else { return }
                                    
                                    if let date: Date = proxy.value(atX: locationX) {
                                        if let closest = findClosestPoint(for: date, in: viewModel.dataPoints) {
                                            if selectedPoint?.id != closest.id {
                                                HapticManager.impact(.light)
                                                selectedPoint = closest
                                            }
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    selectedPoint = nil
                                }
                        )
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - 4. Bandwidth 柱状图 (Bar Chart with Rounded Bars & Scrubbing)
    private var bandwidthBarChartCard: some View {
        let maxBytes = viewModel.dataPoints.map { $0.sum.bytes }.max() ?? 1024
        let yUpper = max(1024.0, Double(maxBytes) * 1.18)
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.purple)
                        Text("Bandwidth Usage")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(viewModel.formatBytes(selectedBandwidthPoint?.sum.bytes ?? viewModel.totalBandwidthBytes))
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(.primary)
                        Text(selectedBandwidthPoint != nil ? "transferred" : "total")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if let selected = selectedBandwidthPoint {
                    let dateStr = formattedPointDate(selected)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 6, height: 6)
                        Text(dateStr)
                            .font(.caption2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.12))
                    .clipShape(Capsule())
                } else {
                    Text("Drag to Inspect")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(minHeight: 48)
            
            Chart {
                ForEach(viewModel.dataPoints) { point in
                    let ptDate = dateFromString(point.dimensions.datetime ?? point.dimensions.date ?? "")
                    let isSelected = selectedBandwidthPoint?.id == point.id
                    
                    BarMark(
                        x: .value("Date", ptDate),
                        y: .value("Bytes", point.sum.bytes),
                        width: .fixed(8)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: isSelected
                                ? [Color.purple.opacity(0.95), Color.purple]
                                : [Color.purple.opacity(0.65), Color.purple.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                
                if let selected = selectedBandwidthPoint {
                    let selDate = dateFromString(selected.dimensions.datetime ?? selected.dimensions.date ?? "")
                    RuleMark(x: .value("Date", selDate))
                        .foregroundStyle(Color.purple.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                }
            }
            .id("bandwidth_chart_\(viewModel.loadedDays)")
            .frame(height: 200)
            .chartPlotStyle { plot in
                plot.clipped()
            }
            .chartYScale(domain: 0...yUpper)
            .chartXScale(domain: chartXRange)
            .transaction { $0.animation = nil }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.secondary.opacity(0.2))
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
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    if let bytes = value.as(Int.self) {
                        AxisValueLabel {
                            Text(viewModel.formatBytes(bytes))
                                .frame(width: 52, alignment: .trailing)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let origin = geo[proxy.plotAreaFrame].origin
                                    let locationX = value.location.x - origin.x
                                    guard locationX >= 0, locationX <= proxy.plotAreaSize.width else { return }
                                    
                                    if let date: Date = proxy.value(atX: locationX) {
                                        if let closest = findClosestPoint(for: date, in: viewModel.dataPoints) {
                                            if selectedBandwidthPoint?.id != closest.id {
                                                HapticManager.impact(.light)
                                                selectedBandwidthPoint = closest
                                            }
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    selectedBandwidthPoint = nil
                                }
                        )
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
            
            LabeledContent {
                Text(viewModel.formatBytes(viewModel.totalCachedBandwidthBytes))
                    .font(.caption.weight(.semibold).monospacedDigit())
            } label: {
                Text("Origin Bandwidth Saved")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            LabeledContent {
                Text(verbatim: String(format: "%.1f%%", viewModel.cachedRatio * 100))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(viewModel.cachedRatio > 0.5 ? Color.green : Color.orange)
            } label: {
                Text("Edge Cache Ratio")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Helpers
    private func dateFromString(_ dateString: String) -> Date {
        DateFormatters.parseChartDate(dateString)
    }
    
    private func formattedPointDate(_ point: AnalyticsDataPoint) -> String {
        let date = dateFromString(point.dimensions.datetime ?? point.dimensions.date ?? "")
        if isHourlyData {
            return date.formatted(date: .omitted, time: .shortened)
        } else {
            return date.formatted(.dateTime.month().day())
        }
    }
    
    private func findClosestPoint(for date: Date, in points: [AnalyticsDataPoint]) -> AnalyticsDataPoint? {
        guard !points.isEmpty else { return nil }
        return points.min(by: {
            let d1 = abs(dateFromString($0.dimensions.datetime ?? $0.dimensions.date ?? "").timeIntervalSince(date))
            let d2 = abs(dateFromString($1.dimensions.datetime ?? $1.dimensions.date ?? "").timeIntervalSince(date))
            return d1 < d2
        })
    }
    
    private func formatNumber(_ num: Int) -> String {
        if num < 1000 { return "\(num)" }
        let k = Double(num) / 1000.0
        if k < 1000 { return String(format: "%.1fK", k) }
        let m = k / 1000.0
        return String(format: "%.2fM", m)
    }
}
