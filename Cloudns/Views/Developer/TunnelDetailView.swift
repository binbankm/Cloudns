import SwiftUI

struct TunnelDetailView: View {
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
    
    var body: some View {
        contentView
            .navigationTitle(tunnel.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
    private var contentView: some View {
        List {
            // Section: Overview
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
            
            // Section: Connector Token / Install Command
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
                            ToastManager.shared.showCopied("Install command copied")
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
            
            // Section: Ingress Public Routing Rules
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
            
            // Section: Connectors
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
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
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
            
            // Section: Danger Zone
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

struct AddIngressRuleSheetView: View {
    @ObservedObject var viewModel: TunnelDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var hostname = ""
    @State private var path = ""
    @State private var serviceURL = "http://localhost:8080"
    @State private var isSaving = false
    @FocusState private var focusedField: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Public Hostname"), footer: Text("Public domain or subdomain to route traffic from (e.g. app.my-domain.com).")) {
                    TextField("app.domain.com", text: $hostname)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: "hostname")
                    TextField("Path Prefix (Optional, e.g. /api)", text: $path)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: "path")
                        .onSubmit { focusedField = "service" }
                }
                
                Section(header: Text("Target Service"), footer: Text("Address of your local service (e.g. http://localhost:8080, tcp://localhost:22, or http_status:404).")) {
                    TextField("http://localhost:8080", text: $serviceURL)
                        .keyboardType(.URL)
                        .submitLabel(.done)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: "serviceURL")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .centerConstrainedWidth(maxWidth: 840)
            .navigationTitle("New Hostname Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticManager.impact(.medium)
                        Task {
                            isSaving = true
                            let cleanHost = hostname.trimmingCharacters(in: .whitespaces)
                            let cleanPath = path.trimmingCharacters(in: .whitespaces)
                            let cleanSvc = serviceURL.trimmingCharacters(in: .whitespaces)
                            let success = await viewModel.addIngressRule(hostname: cleanHost, path: cleanPath.isEmpty ? nil : cleanPath, service: cleanSvc)
                            isSaving = false
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(hostname.trimmingCharacters(in: .whitespaces).isEmpty || serviceURL.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
    }
}
