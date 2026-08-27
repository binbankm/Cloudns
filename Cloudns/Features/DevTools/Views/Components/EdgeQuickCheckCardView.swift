import SwiftUI

/// DevTools 顶部一键网络体检看板卡片
struct EdgeQuickCheckCardView: View {
    // MARK: - Properties
    @State private var result: EdgeQuickCheckResult?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    private let devToolsService: DevToolsServiceProtocol = DevToolsService.shared
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.mdSmall) {
            // Header
            HStack {
                Label("Edge Quick Check", systemImage: "bolt.horizontal.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloudnsColor.brandAccent)
                
                Spacer()
                
                Button {
                    HapticManager.impact(.light)
                    performCheck()
                } label: {
                    HStack(spacing: CloudnsSpacing.xs) {
                        if isLoading {
                            ProgressView()
                                .controlSize(.mini)
                                .tint(CloudnsColor.brandAccent)
                        } else {
                            Image(systemName: result == nil ? "play.fill" : "arrow.clockwise")
                                .font(.caption2.weight(.semibold))
                        }
                        Text(result == nil ? "Run Test" : "Recheck")
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, CloudnsSpacing.sm)
                    .padding(.vertical, CloudnsSpacing.xs)
                    .background(CloudnsColor.warningMuted)
                    .foregroundStyle(CloudnsColor.brandAccent)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .accessibilityLabel(result == nil ? "Run Edge Quick Check" : "Recheck Edge Connection")
            }
            
            // Content
            if isLoading && result == nil {
                loadingView
            } else if let res = result {
                resultView(res)
            } else if let error = errorMessage {
                errorView(error)
            } else {
                idleView
            }
        }
        .padding(CloudnsSpacing.md)
        .background(CloudnsColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.lg))
        .cloudnsShadow(.card)
        .task {
            if result == nil {
                performCheck()
            }
        }
    }
    
    // MARK: - Private Views
    
    private var idleView: some View {
        HStack(spacing: CloudnsSpacing.mdSmall) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
                Text("Inspect Edge Connectivity")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text("Detect nearest Anycast PoP, RTT latency & HTTP/3 support.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, CloudnsSpacing.xs)
    }
    
    private var loadingView: some View {
        HStack(spacing: CloudnsSpacing.mdSmall) {
            ProgressView()
                .controlSize(.small)
            
            Text("Probing nearest Cloudflare Anycast node & latency...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, CloudnsSpacing.xs)
    }
    
    private func errorView(_ error: String) -> some View {
        HStack(spacing: CloudnsSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(CloudnsColor.danger)
                .font(.subheadline)
            
            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, CloudnsSpacing.xxs)
    }
    
    private func resultView(_ res: EdgeQuickCheckResult) -> some View {
        VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
            // PoP & Location Banner
            HStack(spacing: CloudnsSpacing.sm) {
                Text(CountryCoordinates.flag(for: res.countryCode))
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: CloudnsSpacing.xs) {
                        Text(res.cityName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                        
                        Text(res.colo)
                            .font(.caption2.weight(.bold).monospaced())
                            .padding(.horizontal, CloudnsSpacing.sm)
                            .padding(.vertical, CloudnsSpacing.xxs)
                            .background(CloudnsColor.warningMuted)
                            .foregroundStyle(CloudnsColor.brandAccent)
                            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.xs))
                    }
                    
                    Text("Anycast Edge PoP Node")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // RTT Badge
                VStack(alignment: .trailing, spacing: CloudnsSpacing.xxs) {
                    HStack(spacing: CloudnsSpacing.xs) {
                        Circle()
                            .fill(latencyColor(res.rttMs))
                            .frame(width: 7, height: 7)
                        
                        Text(verbatim: String(format: "%.0f ms", res.rttMs))
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                    
                    Text("First Packet RTT")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, CloudnsSpacing.xxs)
            
            Divider()
            
            // Sub-metrics Grid
            HStack(spacing: CloudnsSpacing.md) {
                // Protocol
                VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
                    Text("Protocol")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(res.httpVersion.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(res.httpVersion.contains("3") ? .green : .primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // TLS & Security
                VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
                    Text("Security")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(res.tlsVersion)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Client IP
                VStack(alignment: .trailing, spacing: CloudnsSpacing.xxs) {
                    Text("Client IP")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(res.clientIp)
                        .font(.caption.monospaced())
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
    
    // MARK: - Actions
    
    private func performCheck() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let check = try await devToolsService.performEdgeQuickCheck()
                await MainActor.run {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        self.result = check
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.errorMessage = "Failed to connect: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    private func latencyColor(_ ms: Double) -> Color {
        if ms < 50 { return .green }
        if ms < 150 { return .orange }
        return .red
    }
}
