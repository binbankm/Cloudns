import SwiftUI

struct TunnelDetailView: View {
    let accountId: String
    let tunnel: CFTunnel
    @StateObject private var viewModel: TunnelDetailViewModel
    
    init(accountId: String, tunnel: CFTunnel) {
        self.accountId = accountId
        self.tunnel = tunnel
        _viewModel = StateObject(wrappedValue: TunnelDetailViewModel(accountId: accountId, tunnel: tunnel))
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            contentView
        }
        .navigationTitle(tunnel.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.fetchConfiguration()
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchConfiguration()
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && !viewModel.hasFetchedData {
            List {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonRowView()
                }
            }
            .listStyle(.insetGrouped)
        } else {
            List {
                // Section: Overview
                Section(header: Text("Tunnel Overview")) {
                    HStack {
                        Text("Tunnel Name")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(tunnel.name)
                            .font(.body.bold())
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Status")
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(tunnel.isHealthy ? Color.green : Color.red)
                                .frame(width: 6, height: 6)
                            Text((tunnel.status ?? "Inactive").capitalized)
                                .font(.body)
                                .foregroundColor(tunnel.isHealthy ? .green : .red)
                        }
                    }
                    
                    HStack {
                        Text("UUID")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(tunnel.id)
                            .font(.caption2.monospaced())
                            .foregroundColor(.secondary)
                    }
                }
                
                // Section: Ingress Public Routing Rules
                Section(header: Text("Ingress Routing Rules (\(viewModel.ingressRules.count))")) {
                    if viewModel.ingressRules.isEmpty {
                        Text("No public ingress hostnames configured for this tunnel.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.ingressRules) { rule in
                            VStack(alignment: .leading, spacing: 4) {
                                if let host = rule.hostname, !host.isEmpty {
                                    HStack {
                                        Image(systemName: "globe")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        Text(host)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                    }
                                }
                                
                                if let svc = rule.service {
                                    HStack {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                        Text(svc)
                                            .font(.caption.monospaced())
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
                
                // Section: Connectors
                if let conns = tunnel.connections, !conns.isEmpty {
                    Section(header: Text("Active Connectors (\(conns.count))")) {
                        ForEach(conns) { conn in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    if let colo = conn.coloName {
                                        Text(colo.uppercased())
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.12))
                                            .foregroundColor(.blue)
                                            .cornerRadius(4)
                                    }
                                    
                                    if let ip = conn.originIp {
                                        Text(ip)
                                            .font(.caption.monospaced())
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Spacer()
                                    
                                    if let arch = conn.arch {
                                        Text(arch)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if let ver = conn.version {
                                    Text("cloudflared v\(ver)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}
