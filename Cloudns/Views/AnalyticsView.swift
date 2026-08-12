import SwiftUI
import Charts

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
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.hasFetchedData && viewModel.dataPoints.isEmpty {
                    Text("No data available.")
                        .foregroundColor(.secondary)
                        .padding()
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
                            .font(.headline)
                        
                        requestsChart
                        
                        Divider()
                        
                        Text("Bandwidth")
                            .font(.headline)
                        
                        bandwidthChart
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .redacted(reason: !viewModel.hasFetchedData ? .placeholder : [])
            .disabled(!viewModel.hasFetchedData)
        }
        .overlay {
            if viewModel.isLoading && !viewModel.hasFetchedData {
                ProgressView()
            }
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
        if dateString.contains("T") {
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: dateString) ?? Date()
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: dateString) ?? Date()
        }
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
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
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
