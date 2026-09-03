import SwiftUI

// MARK: - HyperdriveDetailView
// Apple HIG Compliant Cloudflare Hyperdrive Database Accelerator Details

struct HyperdriveDetailView: View {
    let accountId: String
    let config: HyperdriveConfig
    @ObservedObject var viewModel: HyperdriveViewModel
    
    var body: some View {
        List {
            Section(header: Text("Accelerator Overview")) {
                LabeledContent("Config Name", value: config.name)
                
                LabeledContent("Config ID") {
                    Text(config.id)
                        .font(HIGTypography.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = config.id
                        ToastManager.shared.showCopied("Config ID Copied")
                        HIGFeedback.copied()
                    } label: {
                        Label("Copy ID", systemImage: "doc.on.doc")
                    }
                }
            }
            
            if let origin = config.origin {
                Section(header: Text("Origin Database")) {
                    LabeledContent("Scheme", value: origin.scheme?.uppercased() ?? "POSTGRES")
                    
                    if let host = origin.host, !host.isEmpty {
                        LabeledContent("Host") {
                            Text(host)
                                .font(HIGTypography.caption.monospaced())
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
                Section(header: Text("Query Caching")) {
                    LabeledContent("Cache Status") {
                        Text(caching.disabled == true ? "Disabled" : "Enabled")
                            .font(HIGTypography.body.weight(.medium))
                            .foregroundStyle(caching.disabled == true ? Color.secondary : HIGColors.success)
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
