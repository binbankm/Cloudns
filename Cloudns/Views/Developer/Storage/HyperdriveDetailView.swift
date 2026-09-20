import SwiftUI

// MARK: - HyperdriveDetailView

// Apple HIG Compliant Cloudflare Hyperdrive Database Accelerator Details

struct HyperdriveDetailView: View {
    let accountId: String
    let initialConfig: HyperdriveConfig
    @ObservedObject var viewModel: HyperdriveViewModel

    @State private var config: HyperdriveConfig
    @State private var isCachingEnabled: Bool
    @State private var maxAgeText: String
    @State private var staleWhileRevalidateText: String
    @State private var metrics: HyperdriveMetrics?
    @State private var isSaving = false
    @State private var isLoadingMetrics = false

    init(accountId: String, config: HyperdriveConfig, viewModel: HyperdriveViewModel) {
        self.accountId = accountId
        self.initialConfig = config
        self.viewModel = viewModel
        self._config = State(initialValue: config)
        let caching = config.caching
        self._isCachingEnabled = State(initialValue: caching?.disabled != true)
        self._maxAgeText = State(initialValue: "\(caching?.maxAge ?? 60)")
        self._staleWhileRevalidateText = State(initialValue: "\(caching?.staleWhileRevalidate ?? 30)")
    }

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

            // MARK: - Interactive Query Caching
            Section {
                Toggle("Enable Query Caching", isOn: $isCachingEnabled)

                if isCachingEnabled {
                    HStack {
                        Text("Max Age (Seconds)")
                        Spacer()
                        TextField("60", text: $maxAgeText)
                            .font(.body.monospacedDigit())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Stale While Revalidate (Seconds)")
                        Spacer()
                        TextField("30", text: $staleWhileRevalidateText)
                            .font(.body.monospacedDigit())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                Button {
                    saveCachingConfig()
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .padding(.trailing, 4)
                        }
                        Text("Save Caching Settings")
                            .font(.body.weight(.semibold))
                        Spacer()
                    }
                }
                .disabled(isSaving)
            } header: {
                Text("Query Caching")
            } footer: {
                Text("Cache repeated SELECT queries at Cloudflare's global edge to reduce origin load.")
            }

            // MARK: - Performance Metrics
            Section("Performance Metrics") {
                if let m = metrics {
                    LabeledContent("Active Connections") {
                        Text("\(m.activeConnections ?? 0)")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.primary)
                    }

                    LabeledContent("Queued Queries") {
                        Text("\(m.queuedQueries ?? 0)")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    if let hitRatio = m.cacheHitRatio {
                        LabeledContent("Cache Hit Ratio") {
                            HStack(spacing: 6) {
                                Text("\(Int(hitRatio * 100))%")
                                    .font(.body.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(hitRatio > 0.5 ? .green : .secondary)
                            }
                        }
                    }
                } else if isLoadingMetrics {
                    HStack {
                        Spacer()
                        ProgressView("Loading metrics…")
                        Spacer()
                    }
                } else {
                    Text("No live metrics recorded yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(config.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await loadData()
        }
        .task {
            await loadData()
        }
    }

    private func loadData() async {
        isLoadingMetrics = true
        metrics = await viewModel.fetchMetrics(configId: config.id)
        isLoadingMetrics = false
    }

    private func saveCachingConfig() {
        Task {
            isSaving = true
            let maxAge = Int(maxAgeText) ?? 60
            let stale = Int(staleWhileRevalidateText) ?? 30

            if let updated = await viewModel.updateCaching(
                configId: config.id,
                disabled: !isCachingEnabled,
                maxAge: maxAge,
                staleWhileRevalidate: stale
            ) {
                config = updated
                ToastManager.shared.showSuccess("Caching Settings Saved", icon: "bolt.fill")
                HapticManager.notification(.success)
            } else {
                ToastManager.shared.showError("Failed to Save Caching Settings")
                HapticManager.notification(.error)
            }
            isSaving = false
        }
    }
}
