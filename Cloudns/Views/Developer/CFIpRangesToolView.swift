import SwiftUI

struct CFIpRangesToolView: View {
    @StateObject private var viewModel = CFIpRangesViewModel()
    
    private let placeholderRanges = [
        "173.245.48.0/20",
        "103.21.244.0/22",
        "103.22.200.0/22",
        "103.31.4.0/22",
        "141.101.64.0/18",
        "108.162.192.0/18",
        "190.93.240.0/20"
    ]
    
    @ViewBuilder
    private var skeletonContent: some View {
        VStack(spacing: 0) {
            Picker("Protocol", selection: $viewModel.selectedSegment) {
                Text("IPv4 Ranges").tag(0)
                Text("IPv6 Ranges").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            
            List {
                Section(header: Text("Official CIDRs")) {
                    ForEach(placeholderRanges, id: \.self) { cidr in
                        cidrRow(cidr)
                            .skeletonLoading(true)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Cloudflare IP Ranges")
        .navigationBarTitleDisplayMode(.inline)
    }

    var body: some View {
        Group {
            if !viewModel.hasFetchedData {
                skeletonContent
            } else {
                VStack(spacing: 0) {
                    Picker("Protocol", selection: $viewModel.selectedSegment) {
                        Text("IPv4 Ranges (\(viewModel.ipv4List.count))").tag(0)
                        Text("IPv6 Ranges (\(viewModel.ipv6List.count))").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGroupedBackground))
                    
                    contentView
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Cloudflare IP Ranges")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $viewModel.searchText, prompt: "Search CIDR Blocks")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                let text = viewModel.ipv4List.joined(separator: "\n")
                                UIPasteboard.general.string = text
                                HapticManager.notification(.success)
                                ToastManager.shared.showCopied("IPv4 CIDRs copied")
                            } label: {
                                Label("Copy All IPv4", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                let text = viewModel.ipv6List.joined(separator: "\n")
                                UIPasteboard.general.string = text
                                HapticManager.notification(.success)
                                ToastManager.shared.showCopied("IPv6 CIDRs copied")
                            } label: {
                                Label("Copy All IPv6", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                let nginx = (viewModel.ipv4List + viewModel.ipv6List).map { "set_real_ip_from \($0);" }.joined(separator: "\n") + "\nreal_ip_header CF-Connecting-IP;"
                                UIPasteboard.general.string = nginx
                                HapticManager.notification(.success)
                                ToastManager.shared.showCopied("Nginx config copied")
                            } label: {
                                Label("Copy Nginx Real-IP Config", systemImage: "server.rack")
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Export IP Ranges")
                    }
                }
                .refreshable {
                    await viewModel.fetchIPRanges()
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.hasFetchedData)
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchIPRanges()
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            let activeList = viewModel.selectedSegment == 0 ? viewModel.filteredIPv4 : viewModel.filteredIPv6
            if !activeList.isEmpty {
                Section(
                    header: Text(viewModel.selectedSegment == 0 ? "Official IPv4 CIDRs" : "Official IPv6 CIDRs"),
                    footer: Text("Use these official Cloudflare Edge IP subnets for origin firewall rules (iptables, UFW, Nginx).")
                ) {
                    ForEach(activeList, id: \.self) { cidr in
                        cidrRow(cidr)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if viewModel.hasFetchedData {
                let activeList = viewModel.selectedSegment == 0 ? viewModel.filteredIPv4 : viewModel.filteredIPv6
                if let errorMessage = viewModel.errorMessage, viewModel.ipv4List.isEmpty && viewModel.ipv6List.isEmpty {
                    StateOverlayView(
                        state: .error(
                            message: LocalizedStringKey(errorMessage),
                            retryAction: { Task { await viewModel.fetchIPRanges() } }
                        )
                    )
                } else if activeList.isEmpty && !viewModel.searchText.isEmpty {
                    StateOverlayView(
                        state: .search(
                            query: viewModel.searchText,
                            clearAction: { viewModel.searchText = "" }
                        )
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func cidrRow(_ cidr: String) -> some View {
        HStack {
            Image(systemName: "network")
                .foregroundStyle(.blue)
                .font(.caption)
                .accessibilityHidden(true)

            Text(cidr)
                .font(.body.monospacedDigit())
                .foregroundStyle(.primary)

            Spacer()

            Button {
                UIPasteboard.general.string = cidr
                HapticManager.notification(.success)
                ToastManager.shared.showCopied("CIDR copied")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Copy \(cidr)")
        }
        .padding(.vertical, 3)
    }
}
