import SwiftUI

struct DNSRecordsView: View {
    let zoneId: String
    let zoneName: String
    
    @StateObject private var viewModel: DNSRecordsViewModel
    @State private var searchText = ""
    @State private var showingForm = false
    @State private var recordToEdit: DNSRecord? = nil
    
    init(zoneId: String, zoneName: String) {
        self.zoneId = zoneId
        self.zoneName = zoneName
        _viewModel = StateObject(wrappedValue: DNSRecordsViewModel(zoneId: zoneId))
    }
    
    var filteredRecords: [DNSRecord] {
        if searchText.isEmpty {
            return viewModel.records
        } else {
            return viewModel.records.filter { $0.name.lowercased().contains(searchText.lowercased()) || ($0.content ?? "").lowercased().contains(searchText.lowercased()) || $0.type.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var displayRecords: [DNSRecord] {
        if !viewModel.hasFetchedData {
            return DNSRecord.dummyData
        }
        return filteredRecords
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // DNSSEC Panel
                    if let dnssec = viewModel.dnssec {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "lock.shield")
                                    .foregroundColor(.green)
                                Text("DNSSEC")
                                    .font(.headline)
                                Spacer()
                                if dnssec.status == "active" {
                                    Text("Active")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green)
                                        .cornerRadius(8)
                                } else if dnssec.status == "pending" {
                                    Text("Pending")
                                        .font(.caption.bold())
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.yellow)
                                        .cornerRadius(8)
                                }
                            }
                            
                            Text("Protect your domain from DNS spoofing and cache poisoning.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Toggle(isOn: Binding(
                                get: { dnssec.status == "active" || dnssec.status == "pending" },
                                set: { _ in Task { await viewModel.toggleDNSSEC() } }
                            )) {
                                Text("Enable DNSSEC")
                                    .font(.body)
                            }
                            .disabled(viewModel.isDNSSECLoading)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }
                    
                    if let errorMessage = viewModel.errorMessage, viewModel.records.isEmpty && viewModel.hasFetchedData {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                            Button("Retry") {
                                Task {
                                    await viewModel.fetchRecords(isRefresh: true)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    } else if viewModel.records.isEmpty && viewModel.hasFetchedData {
                        EmptyStateView(
                            icon: "server.rack",
                            title: "No DNS Records",
                            message: "No DNS records found for this domain."
                        )
                    } else if displayRecords.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No Results",
                            message: "No records match your search."
                        )
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(displayRecords) { record in
                                DNSRecordCardView(record: record)
                                    .contextMenu {
                                        Button {
                                            let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
                                            UIPasteboard.general.string = record.content ?? record.name
                                        } label: {
                                            Label("Copy Content", systemImage: "doc.on.doc")
                                        }
                                        
                                        Button {
                                            let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
                                            recordToEdit = record
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive) {
                                            Task {
                                                try? await viewModel.deleteRecord(recordId: record.id)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .padding(.horizontal, 16)
                            }
                            
                            if viewModel.canLoadMore && viewModel.hasFetchedData && searchText.isEmpty {
                                ProgressView()
                                    .onAppear {
                                        Task {
                                            await viewModel.fetchRecords()
                                        }
                                    }
                                    .padding()
                            }
                        }
                        .padding(.vertical, 16)
                        .redacted(reason: !viewModel.hasFetchedData ? .placeholder : [])
                        .disabled(!viewModel.hasFetchedData)
                    }
                }
            }
            .refreshable {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await viewModel.fetchRecords(isRefresh: true) }
                    group.addTask { await viewModel.fetchDNSSEC() }
                }
            }
        }
        .navigationTitle("DNS Records")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    recordToEdit = nil
                    showingForm = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: viewModel.totalCount > 0 ? "Search \(viewModel.totalCount) records" : "Search records")
        .task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    if await viewModel.records.isEmpty {
                        await viewModel.fetchRecords()
                    }
                }
                group.addTask {
                    if await viewModel.dnssec == nil {
                        await viewModel.fetchDNSSEC()
                    }
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            DNSRecordFormView(viewModel: viewModel, existingRecord: nil)
        }
        .sheet(item: $recordToEdit) { record in
            DNSRecordFormView(viewModel: viewModel, existingRecord: record)
        }
    }
}

struct DNSRecordCardView: View {
    let record: DNSRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                // Record Type Badge
                Text(record.type)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .frame(width: 44)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                
                // Record Name
                Text(record.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                // Proxy Status Icon (Orange/Gray Cloud)
                if record.proxiable == true {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 14))
                        .foregroundColor(record.proxied == true ? .orange : .gray)
                } else {
                    Text("DNS Only")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            HStack {
                Text(record.content ?? (record.data != nil ? "Advanced Record Data" : "No content"))
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Spacer()
                
                Text(record.ttl == 1 ? "Auto" : "\(record.ttl)s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let comment = record.comment, !comment.isEmpty {
                Text(comment)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
