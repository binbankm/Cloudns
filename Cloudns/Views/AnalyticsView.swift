import SwiftUI
import Charts
import MapKit

struct AnalyticsView: View {
    let zoneId: String
    let zoneName: String
    
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var timeRange: Int = 30
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time Range Picker
                Picker("Time Range", selection: $timeRange) {
                    Text("Last 24h").tag(1)
                    Text("Last 7 Days").tag(7)
                    Text("Last 30 Days").tag(30)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .onChange(of: timeRange) { newValue in
                    Task {
                        await viewModel.fetchAnalytics(zoneTag: zoneId, days: newValue)
                    }
                }
                
                if let errorMessage = viewModel.errorMessage, viewModel.dataPoints.isEmpty {
                    EmptyStateView.error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task {
                                await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange)
                            }
                        }
                    )
                } else if viewModel.hasFetchedData && viewModel.dataPoints.isEmpty {
                    EmptyStateView(
                        icon: "chart.xyaxis.line",
                        title: "No Analytics Data",
                        message: "Traffic metrics for the selected time range are currently unavailable."
                    )
                } else {
                    // Summary Cards
                    HStack(spacing: 12) {
                        SummaryCard(title: "Total Requests", value: "\(viewModel.totalRequests)", icon: "globe", color: .blue)
                        SummaryCard(title: "Bandwidth", value: viewModel.formatBytes(viewModel.totalBandwidthBytes), icon: "arrow.up.arrow.down", color: .purple)
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        SummaryCard(title: "Cached Requests", value: "\(viewModel.totalCachedRequests)", icon: "bolt.fill", color: .orange)
                        SummaryCard(title: "Hit Ratio", value: String(format: "%.1f%%", viewModel.cachedRatio * 100), icon: "chart.pie.fill", color: .green)
                    }
                    .padding(.horizontal)
                    
                    // Charts
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Requests")
                            .font(.body)
                        
                        requestsChart
                        
                        Divider()
                        
                        Text("Bandwidth")
                            .font(.body)
                        
                        bandwidthChart
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    if !viewModel.mapDataPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Traffic by Country")
                                .font(.body)
                                .padding(.horizontal)
                            
                            trafficMapView
                                .frame(height: 300)
                                .cornerRadius(16)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
            .redacted(reason: !viewModel.hasFetchedData ? .placeholder : [])
            .shimmering(active: !viewModel.hasFetchedData)
            .disabled(!viewModel.hasFetchedData)
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.dataPoints.isEmpty {
                await viewModel.fetchAnalytics(zoneTag: zoneId, days: timeRange)
            }
        }
    }
    
    private func dateFromString(_ dateString: String) -> Date {
        DateFormatters.parseChartDate(dateString)
    }
    
    @ViewBuilder
    private var requestsChart: some View {
        Chart {
            ForEach(viewModel.dataPoints) { point in
                LineMark(
                    x: .value("Date", dateFromString(point.dimensions.datetime ?? point.dimensions.date ?? "")),
                    y: .value("Requests", point.sum.requests)
                )
                .foregroundStyle(.blue)
                .symbol(Circle().strokeBorder(lineWidth: 2))
                .symbolSize(30)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Date", dateFromString(point.dimensions.datetime ?? point.dimensions.date ?? "")),
                    y: .value("Requests", point.sum.requests)
                )
                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.3), .blue.opacity(0)]), startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.catmullRom)
            }
        }
        .frame(height: 250)
        .chartXAxis {
            AxisMarks(preset: .aligned) {
                AxisGridLine().foregroundStyle(.clear)
                if timeRange == 1 {
                    AxisValueLabel(format: .dateTime.hour())
                } else {
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(Color.gray.opacity(0.3))
                if let count = value.as(Int.self) {
                    AxisValueLabel {
                        Text(count, format: .number.notation(.compactName))
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var bandwidthChart: some View {
        Chart {
            ForEach(viewModel.dataPoints) { point in
                BarMark(
                    x: .value("Date", dateFromString(point.dimensions.datetime ?? point.dimensions.date ?? "")),
                    y: .value("Bytes", point.sum.bytes)
                )
                .foregroundStyle(.purple)
            }
        }
        .frame(height: 250)
        .chartXAxis {
            AxisMarks(preset: .aligned) {
                AxisGridLine().foregroundStyle(.clear)
                if timeRange == 1 {
                    AxisValueLabel(format: .dateTime.hour())
                } else {
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(Color.gray.opacity(0.3))
                if let bytes = value.as(Int.self) {
                    AxisValueLabel {
                        Text(viewModel.formatBytes(bytes))
                    }
                }
            }
        }
    }
    
    // MARK: - Map Component
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
            let size = 12.0 // Uniform small size to avoid overlapping
            return MapAnnotationItem(countryCode: code, coordinate: coordinate, size: size, requests: point.count, ratio: ratio)
        }
    }
    
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 30, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 120)
    )
    
    @State private var selectedCountry: String? = nil
    
    @ViewBuilder
    private var trafficMapView: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $mapRegion, annotationItems: mapAnnotations) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedCountry = item.countryCode
                        }
                    } label: {
                        PulsingAnnotationView(item: item, isSelected: selectedCountry == item.countryCode)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Interaction overlay (invisible layer to catch taps outside annotations)
            Button {
                withAnimation(.easeInOut) {
                    selectedCountry = nil
                }
            } label: {
                Color.white.opacity(0.001)
            }
            .buttonStyle(.plain)
            .allowsHitTesting(selectedCountry != nil)
            
            if let selected = selectedCountry,
               let item = mapAnnotations.first(where: { $0.countryCode == selected }) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Country Code: \(item.countryCode)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text("\(item.requests) Requests")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer(minLength: 0)
                    
                    Button(action: {
                        withAnimation(.easeInOut) {
                            selectedCountry = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(UIColor.systemBackground).opacity(0.95))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 40)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
    }
}

struct PulsingAnnotationView: View {
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
    
    var body: some View {
        ZStack {
            // Pulse ring
            Circle()
                .stroke(heatColor, lineWidth: 2)
                .frame(width: item.size, height: item.size)
                .scaleEffect(isPulsing ? 2.5 : 1.0)
                .opacity(isPulsing ? 0.0 : 0.8)
            
            // Core bubble
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

struct SummaryCard: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
}
