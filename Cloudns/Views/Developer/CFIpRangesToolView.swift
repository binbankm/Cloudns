import SwiftUI

struct CFIpRangesToolView: View {
    @StateObject private var viewModel = CFIpRangesViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Address Family", selection: $viewModel.selectedSegment) {
                Text("IPv4 (\(viewModel.ipv4List.count))").tag(0)
                Text("IPv6 (\(viewModel.ipv6List.count))").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGroupedBackground))
            
            contentView
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Cloudflare IP Ranges")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search CIDR Blocks")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        let text = viewModel.ipv4List.joined(separator: "\n")
                        UIPasteboard.general.string = text
                        ToastManager.shared.showCopied("IPv4 CIDRs copied")
                    } label: {
                        Label("Copy All IPv4", systemImage: "doc.on.doc")
                    }
                    
                    Button {
                        let text = viewModel.ipv6List.joined(separator: "\n")
                        UIPasteboard.general.string = text
                        ToastManager.shared.showCopied("IPv6 CIDRs copied")
                    } label: {
                        Label("Copy All IPv6", systemImage: "doc.on.doc")
                    }
                    
                    Button {
                        let nginx = (viewModel.ipv4List + viewModel.ipv6List).map { "set_real_ip_from \($0);" }.joined(separator: "\n") + "\nreal_ip_header CF-Connecting-IP;"
                        UIPasteboard.general.string = nginx
                        ToastManager.shared.showCopied("Nginx config copied")
                    } label: {
                        Label("Copy Nginx Real-IP Config", systemImage: "server.rack")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("复制 IP 范围")
            }
        }
        .refreshable {
            await viewModel.fetchIPRanges()
        }
        .task {
            if !viewModel.hasFetchedData {
                await viewModel.fetchIPRanges()
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        List {
            Section {
                Picker("Protocol", selection: $viewModel.selectedSegment) {
                    Text("IPv4 Ranges (\(viewModel.ipv4List.count))").tag(0)
                    Text("IPv6 Ranges (\(viewModel.ipv6List.count))").tag(1)
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))

            if viewModel.isLoading && !viewModel.hasFetchedData {
                Section {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonRowView()
                    }
                }
            } else if let errorMessage = viewModel.errorMessage, !viewModel.hasFetchedData {
                Section {
                    EmptyStateView.error(
                        message: LocalizedStringKey(errorMessage),
                        retryAction: {
                            Task { await viewModel.fetchIPRanges() }
                        }
                    )
                }
                .listRowBackground(Color.clear)
            } else {
                let activeList = viewModel.selectedSegment == 0 ? viewModel.filteredIPv4 : viewModel.filteredIPv6
                if activeList.isEmpty {
                    Section {
                        EmptyStateView.search(query: viewModel.searchText) {
                            viewModel.searchText = ""
                        }
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Section(header: Text(viewModel.selectedSegment == 0 ? "Official IPv4 CIDRs" : "Official IPv6 CIDRs"), footer: Text("Use these official Cloudflare Edge IP subnets for origin firewall rules (iptables, UFW, Nginx).")) {
                        ForEach(activeList, id: \.self) { cidr in
                            HStack {
                                Image(systemName: "network")
                                    .foregroundStyle(.blue)
                                    .font(.caption)

                                Text(cidr)
                                    .font(.body.monospacedDigit())
                                    .foregroundStyle(.primary)

                                Spacer()

                                Button {
                                    UIPasteboard.general.string = cidr
                                    ToastManager.shared.showCopied("CIDR copied")
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("复制 \(cidr)")
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
