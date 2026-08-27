import SwiftUI

struct TunnelDetailView: View {
    // MARK: - Properties
    let accountId: String
    let tunnel: CFTunnel
    @StateObject private var viewModel: TunnelDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddIngressSheet = false
    @State private var showingDeleteAlert = false
    @State private var isTokenRevealed = false
    
    init(accountId: String, tunnel: CFTunnel) {
        self.accountId = accountId
        self.tunnel = tunnel
        _viewModel = StateObject(wrappedValue: TunnelDetailViewModel(accountId: accountId, tunnel: tunnel))
    }
    
    // MARK: - Body
    var body: some View {
        contentView
            .navigationTitle(tunnel.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddIngressSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Hostname Rule")
                }
            }
            .sheet(isPresented: $showingAddIngressSheet) {
                AddIngressRuleSheetView(viewModel: viewModel)
            }
            .confirmationDialog("Delete Tunnel", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
                Button("Delete '\(tunnel.name)'", role: .destructive) {
                    HapticManager.impact(.medium)
                    Task {
                        let success = await viewModel.deleteTunnel()
                        if success { dismiss() }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to permanently delete tunnel '\(tunnel.name)'? Any active connections will be terminated.")
            }
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
    // MARK: - Private Views
    private var contentView: some View {
        List {
            // MARK: - Overview
            Section(header: Text("Tunnel Overview")) {
                HStack {
                    Text("Tunnel Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(tunnel.name)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
                
                HStack {
                    Text("Status")
                        .foregroundStyle(.secondary)
                    Spacer()
                    CloudnsBadge(tunnel.isHealthy ? .active((tunnel.status ?? "Active").capitalized) : .error((tunnel.status ?? "Inactive").capitalized), isCompact: true)
                }
                
                HStack {
                    Text("UUID")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(tunnel.id)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            
            // MARK: - Connector Token / Install Command
            if !viewModel.hasFetchedData {
                Section(header: Text("Connector Token")) {
                    HStack {
                        Image(systemName: "terminal")
                            .foregroundStyle(.blue)
                        Text("cloudflared tunnel run --token ••••••••••••••••••••••••")
                            .font(.caption.monospaced())
                        Spacer()
                    }
                    .skeletonLoading(true)
                }
            } else if let token = viewModel.token, !token.isEmpty {
                Section(
                    header: Text("Connector Token"),
                    footer: Text("Run this command on your server or container to attach cloudflared to this tunnel.")
                ) {
                    HStack {
                        Button {
                            let cmd = "cloudflared tunnel run --token \(token)"
                            UIPasteboard.general.string = cmd
                            HapticManager.notification(.success)
                            CloudnsToastManager.shared.showCopied("Install command copied")
                        } label: {
                            HStack {
                                Image(systemName: "terminal")
                                    .foregroundStyle(.blue)
                                    .accessibilityHidden(true)
                                Text(isTokenRevealed ? "cloudflared tunnel run --token \(token)" : "cloudflared tunnel run --token ••••••••")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.primary)
                                    .lineLimit(isTokenRevealed ? 3 : 1)
                                Spacer()
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                    .accessibilityHidden(true)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            HapticManager.impact(.light)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isTokenRevealed.toggle()
                            }
                        } label: {
                            Image(systemName: isTokenRevealed ? "eye.slash" : "eye")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(isTokenRevealed ? "Hide token" : "Reveal token")
                    }
                }
            }
            
            // MARK: - Ingress Public Routing Rules
            Section(
                header: HStack {
                    Text("Public Hostnames / Ingress (\(viewModel.ingressRules.count))")
                    Spacer()
                    Button {
                        showingAddIngressSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                },
                footer: Text("Traffic arriving at these public hostnames will be routed to your local private services.")
            ) {
                if !viewModel.hasFetchedData {
                    ForEach(0..<2, id: \.self) { idx in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundStyle(.blue)
                                Text("app\(idx + 1).example.com")
                                    .font(.body.weight(.medium))
                            }
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundStyle(.green)
                                Text("http://localhost:\(8080 + idx)")
                                    .font(.caption.monospaced())
                            }
                        }
                        .padding(.vertical, 3)
                    }
                    .skeletonLoading(true)
                } else if viewModel.ingressRules.isEmpty {
                    Text("No public ingress hostnames configured.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(viewModel.ingressRules.enumerated()), id: \.offset) { index, rule in
                        VStack(alignment: .leading, spacing: 4) {
                            if let host = rule.hostname, !host.isEmpty {
                                HStack {
                                    Image(systemName: "globe")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                        .accessibilityHidden(true)
                                    Text(host)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    if let p = rule.path, !p.isEmpty {
                                        Text(p)
                                            .font(.caption.monospaced())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            } else {
                                Text("Catch-all Fallback")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let svc = rule.service {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                        .accessibilityHidden(true)
                                    Text(svc)
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 3)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if rule.hostname != nil {
                                Button(role: .destructive) {
                                    HapticManager.impact(.medium)
                                    Task { await viewModel.deleteIngressRule(at: index) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            
            // MARK: - Connectors
            if let conns = tunnel.connections, !conns.isEmpty {
                Section(header: Text("Active Connectors (\(conns.count))")) {
                    ForEach(conns) { conn in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                if let colo = conn.coloName {
                                    Text(colo.uppercased())
                                        .font(.caption.monospacedDigit())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.12))
                                        .foregroundStyle(.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.xs))
                                }
                                
                                if let ip = conn.originIp {
                                    Text(ip)
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.primary)
                                }
                                
                                Spacer()
                                
                                if let arch = conn.arch {
                                    Text(arch)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            if let ver = conn.version {
                                Text("cloudflared v\(ver)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
            
            // MARK: - Danger Zone
            Section {
                Button(role: .destructive) {
                    HapticManager.impact(.medium)
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Tunnel")
                            .font(.body.weight(.medium))
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
    }
}
