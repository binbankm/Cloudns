import SwiftUI

// MARK: - HyperdriveDetailView
// Apple HIG Compliant Cloudflare Hyperdrive Database Accelerator Details

struct HyperdriveDetailView: View {
    let accountId: String
    let config: HyperdriveConfig
    @ObservedObject var viewModel: HyperdriveViewModel
    
    var body: some View {
        List {
            Section("Accelerator Overview") {
                LabeledContent("Config Name", value: config.name)
                
                LabeledContent("Config ID") {
                    Text(config.id)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                .contextMenu {
                    Button {
                        copyToClipboard(config.id, toast: "Config ID Copied")
                    } label: {
                        Label("Copy ID", systemImage: "doc.on.doc")
                    }
                }
            }
            
            if let origin = config.origin {
                Section("Origin Database") {
                    LabeledContent("Scheme", value: origin.scheme?.uppercased() ?? "POSTGRES")
                    
                    if let host = origin.host, !host.isEmpty {
                        LabeledContent("Host") {
                            Text(host)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    LabeledContent("Port", value: "\(origin.port ?? 5432)")
                    
                    if let db = origin.database, !db.isEmpty {
                        LabeledContent("Database Name", value: db)
                    }
                    
                    if let user = origin.user, !user.isEmpty {
                        LabeledContent("User", value: user)
                    }
                }
            }
            
            if let caching = config.caching {
                Section("Query Caching") {
                    LabeledContent("Cache Status") {
                        Text(caching.disabled == true ? LocalizedStringKey("Disabled") : LocalizedStringKey("Enabled"))
                            .font(.body.weight(.medium))
                            .foregroundStyle(caching.disabled == true ? Color.secondary : Color.green)
                    }
                    
                    if let maxAge = caching.maxAge {
                        LabeledContent("Max Age", value: "\(maxAge)s")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(config.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
