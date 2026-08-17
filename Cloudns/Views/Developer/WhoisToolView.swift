import SwiftUI

struct WhoisToolView: View {
    @StateObject private var viewModel = WhoisViewModel()
    
    let presets = ["cloudflare.com", "apple.com", "github.com", "google.com"]
    
    var body: some View {
        List {
            // Section 1: Query Input
            Section(header: Text("WHOIS & RDAP Lookup"), footer: Text("Queries global IANA RDAP directory over encrypted HTTPS (no account needed).")) {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .foregroundStyle(.teal)
                    
                    TextField("example.com", text: $viewModel.domainInput)
                        .font(.body.monospacedDigit())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await viewModel.performLookup() }
                        }
                    
                    if !viewModel.domainInput.isEmpty {
                        Button {
                            viewModel.domainInput = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button {
                        Task { await viewModel.performLookup() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Query")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(viewModel.domainInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
                }
                
                // Quick Presets
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presets, id: \.self) { preset in
                            Button {
                                viewModel.domainInput = preset
                                Task { await viewModel.performLookup() }
                            } label: {
                                Text(preset)
                                    .font(.caption.monospacedDigit())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color(UIColor.tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            
            // Section 2: Results
            if let error = viewModel.errorMessage {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Lookup Failed", systemImage: "exclamationmark.triangle.fill")
                            .font(.body)
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            } else if let info = viewModel.info {
                whoisDetailsView(info: info)
            } else if viewModel.isLoading {
                whoisDetailsView(info: WhoisInfo.placeholder)
                    .skeletonLoading(true)
            }
        }
        .navigationTitle("WHOIS")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.25), value: viewModel.info == nil)
        .overlay {
            if let err = viewModel.errorMessage, viewModel.info == nil && !viewModel.isLoading {
                StateOverlayView(
                    state: .error(
                        message: LocalizedStringKey(err),
                        retryAction: { Task { await viewModel.performLookup() } }
                    )
                )
            }
        }
        .task {
            if viewModel.info == nil {
                await viewModel.performLookup()
            }
        }
    }
    
    @ViewBuilder
    private func whoisDetailsView(info: WhoisInfo) -> some View {
        Section(header: Text("Registration Information")) {
            HStack {
                Text("Domain Name")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(info.domain)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            
            if let reg = info.registrar {
                HStack {
                    Text("Registrar")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(reg)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            if let created = info.created {
                HStack {
                    Text("Created Date")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatDate(created))
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.primary)
                }
            }
            
            if let updated = info.updated {
                HStack {
                    Text("Updated Date")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatDate(updated))
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.primary)
                }
            }
            
            if let expires = info.expires {
                HStack {
                    Text("Expiration Date")
                        .foregroundStyle(.secondary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatDate(expires))
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.primary)
                        
                        let days = Calendar.current.dateComponents([.day], from: Date(), to: expires).day ?? 0
                        Text(days > 0 ? "\(days) days remaining" : "Expired")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(days > 30 ? .green : .red)
                    }
                }
            }
        }
        
        // Section: Domain Statuses
        if !info.statuses.isEmpty {
            Section(header: Text("Domain Statuses (\(info.statuses.count))")) {
                ForEach(info.statuses, id: \.self) { status in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.teal)
                            .frame(width: 6, height: 6)
                        Text(status)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        
        // Section: Nameservers
        if !info.nameservers.isEmpty {
            Section(header: Text("Authoritative Nameservers (\(info.nameservers.count))")) {
                ForEach(info.nameservers, id: \.self) { ns in
                    HStack {
                        Image(systemName: "server.rack")
                            .font(.caption)
                            .foregroundStyle(.teal)
                            .accessibilityHidden(true)
                        Text(ns.lowercased())
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.primary)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = ns.lowercased()
                            HapticManager.notification(.success)
                            ToastManager.shared.showCopied("\(ns.lowercased()) copied")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Copy \(ns.lowercased())")
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        DateFormatters.yearMonthDayHourMinute.string(from: date)
    }
}
