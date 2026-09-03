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
                    .higTouchTarget(44)
                }
            }
            .sheet(isPresented: $showingAddIngressSheet) {
                AddIngressRuleSheetView(viewModel: viewModel)
                    .higToast()
            }
            .confirmationDialog("Delete Tunnel", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
                Button("Delete '\(tunnel.name)'", role: .destructive) {
                    Task {
                        let success = await viewModel.deleteTunnel()
                        if success {
                            ToastManager.shared.showSuccess("Tunnel Deleted", icon: "trash.fill")
                            HIGFeedback.success()
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
                            HIGFeedback.success()
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
            .overlay {
                if !viewModel.hasFetchedData && viewModel.isLoading {
                    HIGContentState(.loading(message: "Loading Tunnel Config…"))
                }
            }
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
            Section(header: Text("Tunnel Overview")) {
                LabeledContent("Tunnel Name", value: tunnel.name)
                    .font(HIGTypography.body)
                
                LabeledContent("Status") {
                    HIGBadge(tunnel.isHealthy ? .active((tunnel.status ?? "Active").capitalized) : .error((tunnel.status ?? "Inactive").capitalized), isCompact: true)
                }
                
                LabeledContent("UUID") {
                    Text(tunnel.id)
                        .font(HIGTypography.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            
            // MARK: - Connector Token / Install Command
            if let token = viewModel.token, !token.isEmpty {
                Section(
                    header: Text("Connector Token"),
                    footer: Text("Run this command on your server or container to attach cloudflared to this tunnel.")
                ) {
                    HStack {
                        Button {
                            let cmd = "cloudflared tunnel run --token \(token)"
                            UIPasteboard.general.string = cmd
                            ToastManager.shared.showCopied("Install Command Copied")
                            HIGFeedback.copied()
                        } label: {
                            HStack(spacing: HIGTokens.Spacing.md) {
                                ListRowIcon(icon: "terminal.fill", color: .blue)
                                Text(isTokenRevealed ? "cloudflared tunnel run --token \(token)" : "cloudflared tunnel run --token ••••••••")
                                    .font(HIGTypography.caption.monospaced())
                                    .foregroundStyle(.primary)
                                    .lineLimit(isTokenRevealed ? 3 : 1)
                                Spacer()
                                Image(systemName: "doc.on.doc")
                                    .font(HIGTypography.caption)
                                    .foregroundStyle(Color.higAccent)
                                    .accessibilityHidden(true)
                            }
                        }
                        .buttonStyle(.plain)
                        .higTouchTarget(44)
                        
                        Button {
                            HIGFeedback.impact(.light)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isTokenRevealed.toggle()
                            }
                        } label: {
                            Image(systemName: isTokenRevealed ? "eye.slash" : "eye")
                                .font(HIGTypography.caption)
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
                    .higTouchTarget(44)
                },
                footer: Text("Traffic arriving at these public hostnames will be routed to your local private services.")
            ) {
                if viewModel.ingressRules.isEmpty {
                    Text("No public ingress hostnames configured.")
                        .font(HIGTypography.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(viewModel.ingressRules.enumerated()), id: \.offset) { index, rule in
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            if let host = rule.hostname, !host.isEmpty {
                                HStack {
                                    Image(systemName: "globe")
                                        .font(HIGTypography.caption)
                                        .foregroundStyle(Color.higAccent)
                                        .accessibilityHidden(true)
                                    Text(host)
                                        .font(HIGTypography.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    if let p = rule.path, !p.isEmpty {
                                        Text(p)
                                            .font(HIGTypography.caption.monospaced())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            } else {
                                Text("Catch-all Fallback")
                                    .font(HIGTypography.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let svc = rule.service {
                                HStack(spacing: HIGTokens.Spacing.xs) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(HIGTypography.caption2)
                                        .foregroundStyle(HIGColors.success)
                                        .accessibilityHidden(true)
                                    Text(svc)
                                        .font(HIGTypography.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, HIGTokens.Spacing.xxs)
                        .contextMenu {
                            if let host = rule.hostname {
                                Button {
                                    UIPasteboard.general.string = host
                                    ToastManager.shared.showCopied("Hostname Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy Hostname", systemImage: "doc.on.doc")
                                }
                            }
                            if let svc = rule.service {
                                Button {
                                    UIPasteboard.general.string = svc
                                    ToastManager.shared.showCopied("Origin Service Copied")
                                    HIGFeedback.copied()
                                } label: {
                                    Label("Copy Origin Service", systemImage: "server.rack")
                                }
                            }
                            
                            if rule.hostname != nil {
                                Divider()
                                
                                Button(role: .destructive) {
                                    ingressIndexToDelete = index
                                    showingDeleteIngressAlert = true
                                    HIGFeedback.impact(.medium)
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
                                    HIGFeedback.impact(.medium)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(HIGColors.error)
                            }
                        }
                    }
                }
            }
            
            // MARK: - Connectors
            if let conns = tunnel.connections, !conns.isEmpty {
                Section(header: Text("Active Connectors (\(conns.count))")) {
                    ForEach(conns) { conn in
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xxs) {
                            HStack {
                                if let colo = conn.coloName {
                                    Text(colo.uppercased())
                                        .font(HIGTypography.caption.monospaced())
                                        .padding(.horizontal, HIGTokens.Spacing.xs)
                                        .padding(.vertical, HIGTokens.Spacing.xxs)
                                        .background(Color.blue.opacity(0.12))
                                        .foregroundStyle(.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.xs, style: .continuous))
                                }
                                
                                if let ip = conn.originIp {
                                    Text(ip)
                                        .font(HIGTypography.caption.monospaced())
                                        .foregroundStyle(.primary)
                                }
                                
                                Spacer()
                                
                                if let arch = conn.arch {
                                    Text(arch)
                                        .font(HIGTypography.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            if let ver = conn.version {
                                Text("cloudflared v\(ver)")
                                    .font(HIGTypography.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, HIGTokens.Spacing.xxs)
                    }
                }
            }
            
            // MARK: - Danger Zone
            Section {
                Button(role: .destructive) {
                    HIGFeedback.impact(.medium)
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Tunnel")
                            .font(HIGTypography.body.weight(.medium))
                        Spacer()
                    }
                }
                .tint(HIGColors.error)
                .higTouchTarget(44)
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
                Section(header: Text("Public Hostname"), footer: Text("Incoming requests to this public domain and path will route through the tunnel.")) {
                    TextField("sub.example.com", text: $hostname)
                        .font(HIGTypography.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                    
                    TextField("Path (Optional, e.g. /api)", text: $path)
                        .font(HIGTypography.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                }
                
                Section(header: Text("Internal Origin Service"), footer: Text("Service URL accessible from where cloudflared is running, e.g. http://localhost:3000, tcp://192.168.1.100:22")) {
                    TextField("http://localhost:8080", text: $service)
                        .font(HIGTypography.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Ingress Rule")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .higTouchTarget(44)
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
                                HIGFeedback.success()
                                ToastManager.shared.showSuccess("Ingress Rule Added", icon: "network.badge.shield.half.filled")
                                dismiss()
                            } else {
                                HIGFeedback.error()
                            }
                            isSaving = false
                        }
                    }
                    .disabled(hostname.trimmingCharacters(in: .whitespaces).isEmpty || service.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                    .higTouchTarget(44)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
