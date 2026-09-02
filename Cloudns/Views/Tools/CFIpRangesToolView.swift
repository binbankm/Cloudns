import SwiftUI

// MARK: - CFIpRangesToolView
// Apple HIG Compliant Cloudflare IP Range Matcher & Firewall Exporter

struct CFIpRangesToolView: View {
    @StateObject private var viewModel = CFIpRangesViewModel()
    @State private var testIpInput = ""
    @State private var testResult: String?
    @State private var showingExportSheet = false
    @State private var exportFormat = 0 // 0: Nginx, 1: Apache, 2: UFW, 3: Caddy, 4: iptables, 5: JSON
    
    private let exportFormats = ["Nginx", "Apache", "UFW", "Caddy", "iptables", "JSON"]
    
    var body: some View {
        List {
            // 1. IP Range Tester
            Section(header: Text("Cloudflare IP Matcher & Calculator"), footer: Text("Verifies if an IP address belongs to Cloudflare's official proxy edge CIDR network blocks.")) {
                HStack(spacing: HIGTokens.Spacing.sm) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(HIGTypography.body)
                        .foregroundStyle(Color.higAccent)
                        .accessibilityHidden(true)
                    
                    TextField("Enter IP e.g. 104.21.45.12", text: $testIpInput)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(HIGTypography.body.monospacedDigit())
                        .submitLabel(.search)
                        .onSubmit {
                            testIP()
                        }
                    
                    if !testIpInput.isEmpty {
                        Button {
                            testIpInput = ""
                            testResult = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .higTouchTarget(44)
                        .accessibilityLabel("Clear Input")
                    }
                }
                
                Button {
                    testIP()
                } label: {
                    HStack(spacing: HIGTokens.Spacing.xs) {
                        Image(systemName: "shield.righthalf.filled")
                        Text("Test If IP Is Cloudflare Proxy")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.higPressable)
                .disabled(testIpInput.trimmingCharacters(in: .whitespaces).isEmpty)
                
                if let result = testResult {
                    HStack(spacing: HIGTokens.Spacing.xs) {
                        Image(systemName: result.contains("Official") ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(result.contains("Official") ? HIGColors.success : HIGColors.error)
                        Text(result)
                            .font(HIGTypography.subheadline)
                            .foregroundStyle(result.contains("Official") ? HIGColors.success : HIGColors.error)
                    }
                }
            }
            
            // 2. IPv4 Ranges
            Section(header: HStack {
                Text("Official IPv4 CIDR Ranges (\(viewModel.ipv4List.count))")
                Spacer()
                Button {
                    copyList(viewModel.ipv4List, title: "IPv4 Ranges")
                } label: {
                    Label("Copy All", systemImage: "doc.on.doc")
                        .font(HIGTypography.caption.weight(.semibold))
                }
            }) {
                ForEach(viewModel.ipv4List, id: \.self) { cidr in
                    HStack {
                        Text(cidr)
                            .font(HIGTypography.subheadline.monospaced())
                            .foregroundStyle(.primary)
                        Spacer()
                        HIGBadge(.active("IPv4"), isCompact: true)
                    }
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = cidr
                            ToastManager.shared.showCopied("CIDR Copied")
                            HIGFeedback.copied()
                        } label: {
                            Label("Copy CIDR", systemImage: "doc.on.doc")
                        }
                    }
                }
            }
            
            // 3. IPv6 Ranges
            Section(header: HStack {
                Text("Official IPv6 CIDR Ranges (\(viewModel.ipv6List.count))")
                Spacer()
                Button {
                    copyList(viewModel.ipv6List, title: "IPv6 Ranges")
                } label: {
                    Label("Copy All", systemImage: "doc.on.doc")
                        .font(HIGTypography.caption.weight(.semibold))
                }
            }) {
                ForEach(viewModel.ipv6List, id: \.self) { cidr in
                    HStack {
                        Text(cidr)
                            .font(HIGTypography.subheadline.monospaced())
                            .foregroundStyle(.primary)
                        Spacer()
                        HIGBadge(.proxied("IPv6"), isCompact: true)
                    }
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = cidr
                            ToastManager.shared.showCopied("CIDR Copied")
                            HIGFeedback.copied()
                        } label: {
                            Label("Copy CIDR", systemImage: "doc.on.doc")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Cloudflare IP Ranges")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingExportSheet = true
                } label: {
                    Label("Export Rules", systemImage: "square.and.arrow.up")
                }
                .higTouchTarget(44)
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            NavigationStack {
                VStack(spacing: 0) {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(Array(exportFormats.enumerated()), id: \.offset) { index, fmt in
                            Text(fmt).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(HIGTokens.Spacing.lg)
                    
                    ScrollView {
                        Text(generateExportCode())
                            .font(HIGTypography.caption.monospaced())
                            .padding(HIGTokens.Spacing.lg)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .navigationTitle("Firewall Allowlist Export")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { showingExportSheet = false }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            UIPasteboard.general.string = generateExportCode()
                            ToastManager.shared.showCopied("Rules Copied")
                            HIGFeedback.copied()
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .higToast()
        }
        .overlay {
            if viewModel.isLoading && viewModel.ipv4List.isEmpty {
                HIGContentState(.loading(message: "Loading Cloudflare IP Ranges…"))
            }
        }
        .task {
            if viewModel.ipv4List.isEmpty {
                await viewModel.fetchIPRanges()
            }
        }
    }
    
    func testIP() {
        let ip = testIpInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ip.isEmpty else { return }
        
        let allRanges = viewModel.ipv4List + viewModel.ipv6List
        for cidr in allRanges where ipMatchesCIDR(ip: ip, cidr: cidr) {
            testResult = "Official Cloudflare IP (Matched CIDR: \(cidr))"
            HIGFeedback.success()
            return
        }
        testResult = "Not a recognized Cloudflare proxy IP"
        HIGFeedback.warning()
    }
    
    private func ipMatchesCIDR(ip: String, cidr: String) -> Bool {
        if ip == cidr || ip.hasPrefix(cidr.split(separator: "/").first.map(String.init) ?? "xxx") {
            return true
        }
        let parts = cidr.split(separator: "/")
        guard parts.count == 2, let prefix = Int(parts[1]) else { return false }
        let cidrIp = String(parts[0])
        
        let ipOctets = ip.split(separator: ".").compactMap { UInt32($0) }
        let cidrOctets = cidrIp.split(separator: ".").compactMap { UInt32($0) }
        guard ipOctets.count == 4, cidrOctets.count == 4 else { return false }
        
        let ipInt = (ipOctets[0] << 24) | (ipOctets[1] << 16) | (ipOctets[2] << 8) | ipOctets[3]
        let cidrInt = (cidrOctets[0] << 24) | (cidrOctets[1] << 16) | (cidrOctets[2] << 8) | cidrOctets[3]
        let mask = prefix == 0 ? 0 : (~UInt32(0) << (32 - prefix))
        
        return (ipInt & mask) == (cidrInt & mask)
    }
    
    private func generateExportCode() -> String {
        let v4 = viewModel.ipv4List
        let v6 = viewModel.ipv6List
        
        switch exportFormat {
        case 0: // Nginx
            var lines = ["# Cloudflare Real IP Configuration for Nginx"]
            for ip in v4 + v6 {
                lines.append("set_real_ip_from \(ip);")
            }
            lines.append("real_ip_header CF-Connecting-IP;")
            return lines.joined(separator: "\n")
            
        case 1: // Apache
            var lines = ["# Cloudflare RemoteIP Configuration for Apache (.htaccess / httpd.conf)"]
            lines.append("RemoteIPHeader CF-Connecting-IP")
            for ip in v4 + v6 {
                lines.append("RemoteIPTrustedProxy \(ip)")
            }
            return lines.joined(separator: "\n")
            
        case 2: // UFW
            var lines = ["# Cloudflare UFW Allow Rules"]
            for ip in v4 + v6 {
                lines.append("sudo ufw allow proto tcp from \(ip) to any port 80,443")
            }
            return lines.joined(separator: "\n")
            
        case 3: // Caddy
            var lines = ["# Cloudflare Trusted Proxies for Caddyfile", "trusted_proxies static \\"]
            for ip in v4 + v6 {
                lines.append("    \(ip) \\")
            }
            return lines.joined(separator: "\n")
            
        case 4: // iptables
            var lines = ["# Cloudflare iptables Rules"]
            for ip in v4 {
                lines.append("iptables -A INPUT -p tcp -m multiport --dports 80,443 -s \(ip) -j ACCEPT")
            }
            return lines.joined(separator: "\n")
            
        default: // JSON
            let dict: [String: [String]] = ["ipv4_cidrs": v4, "ipv6_cidrs": v6]
            if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
               let str = String(data: data, encoding: .utf8) {
                return str
            }
            return "{}"
        }
    }
    
    private func copyList(_ list: [String], title: String) {
        UIPasteboard.general.string = list.joined(separator: "\n")
        ToastManager.shared.showCopied("\(title) Copied")
        HIGFeedback.copied()
    }
}
