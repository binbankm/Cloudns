import SwiftUI
import Charts
import MapKit

// MARK: - ZoneAnalyticsView
// Apple HIG Compliant Cloudflare Zone Analytics, Swift Charts Aurora Visuals & Global Geolocation Map

struct ZoneAnalyticsView: View {
    let zoneId: String
    let zoneName: String
    
    @StateObject private var viewModel = ZoneAnalyticsViewModel()
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
                .padding(.horizontal, HIGTokens.Spacing.lg)
                .padding(.top, HIGTokens.Spacing.md)
                .padding(.bottom, HIGTokens.Spacing.md)
            
            if !viewModel.hasFetchedData && viewModel.isLoading {
                HIGContentState(.loading(message: "Loading Analytics…"))
            } else if viewModel.hasFetchedData && viewModel.dataPoints.isEmpty {
                ScrollView {
                    VStack {
                        Spacer(minLength: 40)
                        if let errorMessage = viewModel.errorMessage {
                            HIGContentState(
                                .error(
                                    message: LocalizedStringKey(errorMessage),
                                    retryAction: {
                                        Task { await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange) }
                                    }
                                )
                            )
                        } else {
                            HIGContentState(
                                .empty(
                                    title: "No Traffic Data",
                                    systemImage: "chart.xyaxis.line",
                                    description: "No HTTP requests recorded for \(zoneName) in the selected time range."
                                )
                            )
                        }
                        Spacer(minLength: 80)
                    }
                    .frame(minHeight: 450)
                    .padding(.horizontal, HIGTokens.Spacing.lg)
                }
                .refreshable {
                    await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange, isRefresh: true)
                }
            } else {
                ScrollView {
                    VStack(spacing: HIGTokens.Spacing.lg) {
                        // 2. 4 Key Metrics Cards Grid (Non-lazy Grid for rock-solid stability)
                        metricsGrid
                        
                        requestsLineChartCard
                        
                        bandwidthBarChartCard
                        
                        // 5. Traffic by Country Map Section
                        if !viewModel.mapDataPoints.isEmpty {
                            trafficMapCard
                        }
                        
                        // 6. CDN Origin Savings Summary Card
                        insightsCard
                    }
                    .padding(.horizontal, HIGTokens.Spacing.lg)
                    .padding(.bottom, HIGTokens.Spacing.xxl)
                    .opacity(viewModel.isLoading ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
                }
                .refreshable {
                    await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange, isRefresh: true)
                }
            }
        }
        .background(Color.higGroupBackground)
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
        HStack(alignment: .center, spacing: HIGTokens.Spacing.md) {
            Image(systemName: "globe")
                .foregroundStyle(Color.higAccent)
                .font(HIGTypography.title3)
            
            Text(verbatim: zoneName)
                .font(HIGTypography.headline.weight(.semibold))
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
                HIGFeedback.selection()
                selectedPoint = nil
                selectedBandwidthPoint = nil
                Task {
                    await viewModel.fetchAnalytics(zoneTag: zoneId, days: newValue)
                }
            }
        }
        .padding(HIGTokens.Spacing.md + 2)
        .background(Color.higCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous)
                .stroke(Color.higCardBorder, lineWidth: HIGTokens.Elevation.hairlineStroke)
        )
    }
    
    // MARK: - 2. Key Metrics Grid
    private var metricsGrid: some View {
        Grid(horizontalSpacing: HIGTokens.Spacing.md, verticalSpacing: HIGTokens.Spacing.md) {
            GridRow {
                metricCard(
                    title: "Total Requests",
                    value: MetricFormatters.compactNumber(viewModel.totalRequests),
                    icon: "globe",
                    color: .blue,
                    badge: "\(ByteCountFormatters.format(viewModel.totalBandwidthBytes)) Transferred"
                )
                
                metricCard(
                    title: "Cached Requests",
                    value: MetricFormatters.compactNumber(viewModel.totalCachedRequests),
                    icon: "bolt.fill",
                    color: .orange,
                    badge: "\(viewModel.cachedRatio.formatted(.percent.precision(.fractionLength(1)))) Cache Rate"
                )
            }
            
            GridRow {
                metricCard(
                    title: "Cache Hit Ratio",
                    value: viewModel.cachedRatio.formatted(.percent.precision(.fractionLength(1))),
                    icon: "chart.pie.fill",
                    color: HIGColors.success,
                    badge: "Edge Served"
                )
                
                metricCard(
                    title: "Data Transferred",
                    value: ByteCountFormatters.format(viewModel.totalBandwidthBytes),
                    icon: "arrow.up.arrow.down",
                    color: .purple,
                    badge: "\(ByteCountFormatters.format(viewModel.totalCachedBandwidthBytes)) Saved by Cache"
                )
            }
        }
    }
    
    private func metricCard(title: LocalizedStringKey, value: String, icon: String, color: Color, badge: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
            HStack(spacing: HIGTokens.Spacing.xs + 2) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 22, height: 22)
                    Image(systemName: icon)
                        .font(HIGTypography.caption2.weight(.semibold))
                        .foregroundStyle(color)
                }
                .accessibilityHidden(true)
                
                Text(title)
                    .font(HIGTypography.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Spacer()
            }
            
            Spacer(minLength: 2)
            
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            Spacer(minLength: 2)
            
            Text(badge)
                .font(HIGTypography.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(HIGTokens.Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 102, maxHeight: 102, alignment: .topLeading)
        .background(Color.higCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous)
                .stroke(Color.higCardBorder, lineWidth: HIGTokens.Elevation.hairlineStroke)
        )
    }
    
    private var requestsLineChartCard: some View {
        let maxReq = viewModel.dataPoints.map { $0.sum.requests }.max() ?? 10
        let yUpper = max(10.0, Double(maxReq) * 1.18)
        
        return VStack(alignment: .leading, spacing: HIGTokens.Spacing.md) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                    HStack(spacing: HIGTokens.Spacing.xs) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(HIGTypography.caption.weight(.bold))
                            .foregroundStyle(Color.higAccent)
                        Text("Requests Traffic")
                            .font(HIGTypography.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(alignment: .lastTextBaseline, spacing: HIGTokens.Spacing.xs + 2) {
                        Text(verbatim: MetricFormatters.compactNumber(selectedPoint?.sum.requests ?? viewModel.totalRequests))
                            .font(.system(.title, design: .rounded).weight(.bold).monospacedDigit())
                            .foregroundStyle(.primary)
                        Text(selectedPoint != nil ? "requests" : "total")
                            .font(HIGTypography.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if let selected = selectedPoint {
                    let dateStr = formattedPointDate(selected)
                    HStack(spacing: HIGTokens.Spacing.xs) {
                        Circle()
                            .fill(Color.higAccent)
                            .frame(width: 6, height: 6)
                        Text(verbatim: dateStr)
                            .font(HIGTypography.caption2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, HIGTokens.Spacing.sm)
                    .padding(.vertical, HIGTokens.Spacing.xs)
                    .background(Color.higAccentSubtle)
                    .clipShape(Capsule())
                } else {
                    Text("Drag to Inspect")
                        .font(HIGTypography.caption2.weight(.medium))
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
                            colors: [Color.higAccent.opacity(0.32), Color.higAccent.opacity(0.01)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)
                    
                    LineMark(
                        x: .value("Date", ptDate),
                        y: .value("Requests", point.sum.requests)
                    )
                    .foregroundStyle(Color.higAccent)
                    .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                }
                
                if let selected = selectedPoint {
                    let selDate = dateFromString(selected.dimensions.datetime ?? selected.dimensions.date ?? "")
                    RuleMark(x: .value("Date", selDate))
                        .foregroundStyle(Color.higAccent.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                    
                    PointMark(
                        x: .value("Date", selDate),
                        y: .value("Requests", selected.sum.requests)
                    )
                    .symbol {
                        ZStack {
                            Circle()
                                .fill(Color.higAccent.opacity(0.25))
                                .frame(width: 16, height: 16)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .shadow(color: Color.higAccent, radius: 4)
                            Circle()
                                .stroke(Color.higAccent, lineWidth: 2)
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
                    AxisValueLabel(
                        format: isHourlyData ? DateFormatters.chartXAxisHourly : DateFormatters.chartXAxisDaily,
                        collisionResolution: .greedy
                    )
                    .font(HIGTypography.caption2.weight(.medium).monospacedDigit())
                    .foregroundStyle(Color(.tertiaryLabel))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    if let count = value.as(Int.self) {
                        AxisValueLabel {
                            Text(verbatim: MetricFormatters.compactNumber(count))
                                .font(HIGTypography.caption2.weight(.medium).monospacedDigit())
                                .foregroundStyle(Color(.tertiaryLabel))
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
                                                HIGFeedback.selection()
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
        .padding(HIGTokens.Spacing.lg)
        .background(Color.higCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous)
                .stroke(Color.higCardBorder, lineWidth: HIGTokens.Elevation.hairlineStroke)
        )
    }
    
    private var bandwidthBarChartCard: some View {
        let maxBytes = viewModel.dataPoints.map { $0.sum.bytes }.max() ?? 1024
        let yUpper = max(1024.0, Double(maxBytes) * 1.18)
        
        return VStack(alignment: .leading, spacing: HIGTokens.Spacing.md) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                    HStack(spacing: HIGTokens.Spacing.xs) {
                        Image(systemName: "chart.bar.fill")
                            .font(HIGTypography.caption.weight(.bold))
                            .foregroundStyle(.purple)
                        Text("Bandwidth Usage")
                            .font(HIGTypography.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(alignment: .lastTextBaseline, spacing: HIGTokens.Spacing.xs + 2) {
                        Text(verbatim: ByteCountFormatters.format(selectedBandwidthPoint?.sum.bytes ?? viewModel.totalBandwidthBytes))
                            .font(.system(.title, design: .rounded).weight(.bold).monospacedDigit())
                            .foregroundStyle(.primary)
                        Text(selectedBandwidthPoint != nil ? "transferred" : "total")
                            .font(HIGTypography.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if let selected = selectedBandwidthPoint {
                    let dateStr = formattedPointDate(selected)
                    HStack(spacing: HIGTokens.Spacing.xs) {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 6, height: 6)
                        Text(verbatim: dateStr)
                            .font(HIGTypography.caption2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, HIGTokens.Spacing.sm)
                    .padding(.vertical, HIGTokens.Spacing.xs)
                    .background(Color.purple.opacity(0.12))
                    .clipShape(Capsule())
                } else {
                    Text("Drag to Inspect")
                        .font(HIGTypography.caption2.weight(.medium))
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
                    .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.xs, style: .continuous))
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
                    AxisValueLabel(
                        format: isHourlyData ? DateFormatters.chartXAxisHourly : DateFormatters.chartXAxisDaily,
                        collisionResolution: .greedy
                    )
                    .font(HIGTypography.caption2.weight(.medium).monospacedDigit())
                    .foregroundStyle(Color(.tertiaryLabel))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    if let bytes = value.as(Int.self) {
                        AxisValueLabel {
                            Text(verbatim: ByteCountFormatters.format(bytes))
                                .font(HIGTypography.caption2.weight(.medium).monospacedDigit())
                                .foregroundStyle(Color(.tertiaryLabel))
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
                                                HIGFeedback.selection()
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
        .padding(HIGTokens.Spacing.lg)
        .background(Color.higCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous)
                .stroke(Color.higCardBorder, lineWidth: HIGTokens.Elevation.hairlineStroke)
        )
    }
    
    // MARK: - 5. Traffic by Country Map
    private var trafficMapCard: some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.md) {
            HStack {
                Image(systemName: "map.fill")
                    .font(HIGTypography.subheadline)
                    .foregroundStyle(Color.higAccent)
                Text("Traffic by Country / Region")
                    .font(HIGTypography.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("Top Traffic Origins")
                    .font(HIGTypography.caption2)
                    .foregroundStyle(.secondary)
            }
            
            trafficMapView
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.md, style: .continuous))
        }
        .padding(HIGTokens.Spacing.lg)
        .background(Color.higCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous)
                .stroke(Color.higCardBorder, lineWidth: HIGTokens.Elevation.hairlineStroke)
        )
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
                        HIGFeedback.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedCountry = item.countryCode
                        }
                    } label: {
                        PulsingAnnotationView(item: item, isSelected: selectedCountry == item.countryCode)
                    }
                    .buttonStyle(.plain)
                    .higTouchTarget(44)
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
                HStack(spacing: HIGTokens.Spacing.md) {
                    VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
                        Text("Country: \(item.countryCode)")
                            .font(HIGTypography.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("\(MetricFormatters.compactNumber(item.requests)) Requests")
                            .font(HIGTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Button {
                        withAnimation(.easeInOut) { selectedCountry = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .higTouchTarget(44)
                }
                .padding(.horizontal, HIGTokens.Spacing.lg)
                .padding(.vertical, HIGTokens.Spacing.md)
                .background(Color.higCardBackground.opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.md, style: .continuous))
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                .padding(.horizontal, HIGTokens.Spacing.xl)
                .padding(.bottom, HIGTokens.Spacing.md)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - 6. Performance Insights Card
    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: HIGTokens.Spacing.md) {
            Label("Edge Caching Savings", systemImage: "sparkles")
                .font(HIGTypography.subheadline.weight(.semibold))
                .foregroundStyle(Color.higAccent)
            
            LabeledContent {
                Text(verbatim: ByteCountFormatters.format(viewModel.totalCachedBandwidthBytes))
                    .font(HIGTypography.caption.weight(.semibold).monospacedDigit())
            } label: {
                Text("Origin Bandwidth Saved")
                    .font(HIGTypography.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            LabeledContent {
                Text(viewModel.cachedRatio, format: .percent.precision(.fractionLength(1)))
                    .font(HIGTypography.caption.weight(.medium))
                    .foregroundStyle(viewModel.cachedRatio > 0.5 ? HIGColors.success : HIGColors.warning)
            } label: {
                Text("Edge Cache Ratio")
                    .font(HIGTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(HIGTokens.Spacing.md + 2)
        .background(Color.higCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous)
                .stroke(Color.higCardBorder, lineWidth: HIGTokens.Elevation.hairlineStroke)
        )
    }
    
    // MARK: - Helpers
    private func dateFromString(_ dateString: String) -> Date {
        DateFormatters.parseChartDate(dateString)
    }
    
    private func formattedPointDate(_ point: AnalyticsDataPoint) -> String {
        let date = dateFromString(point.dimensions.datetime ?? point.dimensions.date ?? "")
        return DateFormatters.formatChartDetailDate(date, isHourly: isHourlyData)
    }
    
    private func findClosestPoint(for date: Date, in points: [AnalyticsDataPoint]) -> AnalyticsDataPoint? {
        guard !points.isEmpty else { return nil }
        return points.min(by: {
            let d1 = abs(dateFromString($0.dimensions.datetime ?? $0.dimensions.date ?? "").timeIntervalSince(date))
            let d2 = abs(dateFromString($1.dimensions.datetime ?? $1.dimensions.date ?? "").timeIntervalSince(date))
            return d1 < d2
        })
    }
}

// MARK: - MapAnnotationItem & PulsingAnnotationView (Inlined & Cohesive)

struct MapAnnotationItem: Identifiable, Sendable {
    let id: UUID
    let countryCode: String
    let coordinate: CLLocationCoordinate2D
    let size: CGFloat
    let requests: Int
    let ratio: Double
    
    init(
        id: UUID = UUID(),
        countryCode: String,
        coordinate: CLLocationCoordinate2D,
        size: CGFloat = 12.0,
        requests: Int,
        ratio: Double
    ) {
        self.id = id
        self.countryCode = countryCode
        self.coordinate = coordinate
        self.size = size
        self.requests = requests
        self.ratio = ratio
    }
}

struct PulsingAnnotationView: View {
    let item: MapAnnotationItem
    let isSelected: Bool
    @State private var isPulsing = false
    
    init(item: MapAnnotationItem, isSelected: Bool) {
        self.item = item
        self.isSelected = isSelected
    }
    
    private var heatColor: Color {
        switch item.ratio {
        case 0.7...: return HIGColors.error
        case 0.3..<0.7: return HIGColors.warning
        case 0.1..<0.3: return .yellow
        default: return .cyan
        }
    }
    
    var body: some View {
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
