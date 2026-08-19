import SwiftUI

// MARK: - HyperdriveDetailView

struct HyperdriveDetailView: View {
    let accountId: String
    let config: HyperdriveConfig
    @ObservedObject var viewModel: HyperdriveViewModel
    
    var body: some View {
        List {
            Section(header: Text("Accelerator Overview")) {
                HStack {
                    Text("Config Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(config.name)
                        .font(.body.weight(.medium))
                }
                
                HStack {
                    Text("Config ID")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(config.id)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            
            if let origin = config.origin {
                Section(header: Text("Origin Database")) {
                    HStack {
                        Text("Scheme")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(origin.scheme?.uppercased() ?? "POSTGRES")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Text("Host")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(origin.host ?? "")
                            .font(.caption.monospaced())
                    }
                    
                    HStack {
                        Text("Port")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(origin.port ?? 5432)")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Text("Database Name")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(origin.database ?? "")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Text("User")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(origin.user ?? "")
                            .font(.subheadline)
                    }
                }
            }
            
            if let caching = config.caching {
                Section(header: Text("Query Caching")) {
                    HStack {
                        Text("Cache Status")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(caching.disabled == true ? "Disabled" : "Enabled")
                            .font(.subheadline)
                            .foregroundStyle(caching.disabled == true ? Color.secondary : Color.green)
                    }
                    
                    if let maxAge = caching.maxAge {
                        HStack {
                            Text("Max Age")
                            .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(maxAge)s")
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(config.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
