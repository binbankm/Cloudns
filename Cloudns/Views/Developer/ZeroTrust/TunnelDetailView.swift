import SwiftUI

// MARK: - TunnelDetailView
// Apple HIG Compliant Cloudflare Zero Trust Tunnel Inspector & Ingress Rules

struct TunnelDetailView: View {
    let accountId: String
    let tunnel: CFTunnel
    @StateObject private var viewModel: TunnelDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddIngressSheet = false
    @State private var showingDeleteAlert = false
    @State private var isTokenRevealed = false
    @State private var ingressIndexToDelete: Int?
    @State private var showingDeleteIngressAlert = false
    
    init(accountId: String, tunnel: CFTunnel) {
        self.accountId = accountId
        self.tunnel = tunnel
        _viewModel = StateObject(wrappedValue: TunnelDetailViewModel(accountId: accountId, tunnel: tunnel))
    }
    
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
                    Task {
                        let success = await viewModel.deleteTunnel()
                        if success {
                            ToastManager.shared.showSuccess("Tunnel Deleted", icon: "trash.fill")
                            HapticManager.notification(.success)
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to permanently delete tunnel '\(tunnel.name)'? Any active connections will be terminated.")
            }
            .confirmationDialog("Delete Ingress Rule", isPresented: $showingDeleteIngressAlert, titleVisibility: .visible) {
                if let idx = ingressIndexToDelete {
                    Button("Delete Rule", role: .destructive) {
                        Task {
                            await viewModel.deleteIngressRule(at: idx)
                            ToastManager.shared.showSuccess("Ingress Rule Deleted", icon: "trash.fill")
                            HapticManager.notification(.success)
                            ingressIndexToDelete = nil
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    ingressIndexToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete this hostname routing rule?")
            }
            .refreshable {
                await viewModel.fetchConfiguration()
            }
            .listState(
                isLoading: !viewModel.hasFetchedData && viewModel.isLoading,
                loadingMessage: "Loading Tunnel Config…"
            )
            .task {
                if !viewModel.hasFetchedData {
                    await viewModel.fetchConfiguration()
                }
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            // MARK: - Overview
            Section("Tunnel Overview") {
                LabeledContent("Tunnel Name", value: tunnel.name)
                    .font(.body)
                
                LabeledContent("Status") {
                    Text((tunnel.status ?? "Active").capitalized)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(tunnel.isHealthy ? .green : .red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill((tunnel.isHealthy ? Color.green : Color.red).opacity(0.12)))
                }
                
                LabeledContent("UUID") {
                    Text(tunnel.id)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            
            // MARK: - Connector Token / Install Command
            if let token = viewModel.token, !token.isEmpty {
                Section {
                    HStack {
                        Button {
                            let cmd = "cloudflared tunnel run --token \(token)"
                            copyToClipboard(cmd, toast: "Install Command Copied")
                        } label: {
                            HStack(spacing: 12) {
                                ListRowIcon(icon: "terminal.fill", color: .blue)
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
                } header: {
                    Text("Connector Token")
                } footer: {
                    Text("Run this command on your server or container to attach cloudflared to this tunnel.")
                }
            }
            
            // MARK: - Ingress Public Routing Rules
            Section {
                if viewModel.ingressRules.isEmpty {
                    Text("No public ingress hostnames configured.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(viewModel.ingressRules.enumerated()), id: \.offset) { index, rule in
                        VStack(alignment: .leading, spacing: 3) {
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
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                        .accessibilityHidden(true)
                                    Text(svc)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                        .contextMenu {
                            if let host = rule.hostname {
                                Button {
                                    copyToClipboard(host, toast: "Hostname Copied")
                                } label: {
                                    Label("Copy Hostname", systemImage: "doc.on.doc")
                                }
                            }
                            if let svc = rule.service {
                                Button {
                                    copyToClipboard(svc, toast: "Origin Service Copied")
                                } label: {
                                    Label("Copy Origin Service", systemImage: "server.rack")
                                }
                            }
                            
                            if rule.hostname != nil {
                                Divider()
                                
                                Button(role: .destructive) {
                                    ingressIndexToDelete = index
                                    showingDeleteIngressAlert = true
                                    HapticManager.impact(.medium)
                                } label: {
                                    Label("Delete Ingress Rule", systemImage: "trash")
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if rule.hostname != nil {
                                Button(role: .destructive) {
                                    ingressIndexToDelete = index
                                    showingDeleteIngressAlert = true
                                    HapticManager.impact(.medium)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Public Hostnames / Ingress (\(viewModel.ingressRules.count))")
                    Spacer()
                    Button {
                        showingAddIngressSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            } footer: {
                Text("Traffic arriving at these public hostnames will be routed to your local private services.")
            }
            
            // MARK: - Connectors
            if let conns = tunnel.connections, !conns.isEmpty {
                Section("Active Connectors (\(conns.count))") {
                    ForEach(conns) { conn in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                if let colo = conn.coloName {
                                    Text(colo.uppercased())
                                        .font(.caption.monospaced())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.12))
                                        .foregroundStyle(.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                }
                                
                                if let ip = conn.originIp {
                                    Text(ip)
                                        .font(.caption.monospaced())
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
                        .padding(.vertical, 2)
                    }
                }
            }
            
            // MARK: - Danger Zone
            Section {
                Button(role: .destructive) {
                    HapticManager.impact(.medium)
                    showingDeleteAlert = true
                } label: {
                    Text("Delete Tunnel")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - AddIngressRuleSheetView (Inlined & Cohesive)

struct AddIngressRuleSheetView: View {
    @ObservedObject var viewModel: TunnelDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var hostname = ""
    @State private var path = ""
    @State private var service = "http://localhost:8080"
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("sub.example.com", text: $hostname)
                        .font(.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    
                    TextField("Path (Optional, e.g. /api)", text: $path)
                        .font(.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                } header: {
                    Text("Public Hostname")
                } footer: {
                    Text("Incoming requests to this public domain and path will route through the tunnel.")
                }
                
                Section {
                    TextField("http://localhost:8080", text: $service)
                        .font(.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                } header: {
                    Text("Internal Origin Service")
                } footer: {
                    Text("Service URL accessible from where cloudflared is running, e.g. http://localhost:3000, tcp://192.168.1.100:22")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Ingress Rule")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            let success = await viewModel.addIngressRule(
                                hostname: hostname.trimmingCharacters(in: .whitespaces),
                                path: path.isEmpty ? nil : path.trimmingCharacters(in: .whitespaces),
                                service: service.trimmingCharacters(in: .whitespaces)
                            )
                            if success {
                                HapticManager.notification(.success)
                                ToastManager.shared.showSuccess("Ingress Rule Added", icon: "network.badge.shield.half.filled")
                                dismiss()
                            } else {
                                HapticManager.notification(.error)
                            }
                            isSaving = false
                        }
                    }
                    .disabled(hostname.trimmingCharacters(in: .whitespaces).isEmpty || service.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
