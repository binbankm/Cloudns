import SwiftUI

struct PagesBindingsView: View {
    let project: PagesProject
    @State private var selectedEnv = "production" // "production" | "preview"
    
    private var currentConfig: PagesEnvConfig? {
        selectedEnv == "production" ? project.deploymentConfigs?.production : project.deploymentConfigs?.preview
    }
    
    var body: some View {
        List {
            // Environment Picker
            Section {
                Picker("Environment", selection: $selectedEnv) {
                    Text("Production").tag("production")
                    Text("Preview").tag("preview")
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedEnv) { _ in
                    HapticManager.impact(.light)
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            
            // Section 1: Environment Variables
            Section(
                header: Text("Environment Variables"),
                footer: Text("Plaintext variables can be viewed directly. Secret variables are encrypted and masked for security.")
            ) {
                if let envVars = currentConfig?.envVars, !envVars.isEmpty {
                    ForEach(Array(envVars.keys.sorted()), id: \.self) { key in
                        if let item = envVars[key] {
                            HStack(alignment: .center, spacing: 12) {
                                Image(systemName: item.isSecret ? "key.fill" : "slider.horizontal.3")
                                    .font(.body)
                                    .foregroundStyle(item.isSecret ? .orange : .blue)
                                    .frame(width: 26, height: 26)
                                    .background((item.isSecret ? Color.orange : Color.blue).opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .accessibilityHidden(true)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(key)
                                        .font(.body.monospacedDigit().weight(.medium))
                                        .foregroundStyle(.primary)
                                    
                                    if let val = item.value, !val.isEmpty {
                                        Text(val)
                                            .font(.caption.monospaced())
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    } else {
                                        Text("•••••••• (Encrypted Secret)")
                                            .font(.caption.monospaced())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(item.isSecret ? "SECRET" : "VARIABLE")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(item.isSecret ? .orange : .blue)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background((item.isSecret ? Color.orange : Color.blue).opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .padding(.vertical, 2)
                            .contextMenu {
                                if let val = item.value {
                                    Button {
                                        UIPasteboard.general.string = val
                                        HapticManager.notification(.success)
                                        ToastManager.shared.showCopied("Value copied")
                                    } label: {
                                        Label("Copy Value", systemImage: "doc.on.doc")
                                    }
                                }
                                Button {
                                    UIPasteboard.general.string = key
                                    HapticManager.notification(.success)
                                    ToastManager.shared.showCopied("Key copied")
                                } label: {
                                    Label("Copy Key Name", systemImage: "doc.on.doc")
                                }
                            }
                        }
                    }
                } else {
                    Text("No environment variables configured for \(selectedEnv.capitalized).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Section 2: KV Namespaces
            if let kv = currentConfig?.kvNamespaces, !kv.isEmpty {
                Section(header: Text("KV Namespaces (\(kv.count))")) {
                    ForEach(Array(kv.keys.sorted()), id: \.self) { key in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(key)
                                    .font(.body.weight(.medium))
                                if let ns = kv[key]?.namespaceId {
                                    Text(ns)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text("KV")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            
            // Section 3: D1 Databases
            if let d1 = currentConfig?.d1Databases, !d1.isEmpty {
                Section(header: Text("D1 Databases (\(d1.count))")) {
                    ForEach(Array(d1.keys.sorted()), id: \.self) { key in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(key)
                                    .font(.body.weight(.medium))
                                if let id = d1[key]?.id {
                                    Text(id)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text("D1")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            
            // Section 4: R2 Buckets
            if let r2 = currentConfig?.r2Buckets, !r2.isEmpty {
                Section(header: Text("R2 Buckets (\(r2.count))")) {
                    ForEach(Array(r2.keys.sorted()), id: \.self) { key in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(key)
                                    .font(.body.weight(.medium))
                                if let bucket = r2[key]?.name {
                                    Text(bucket)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text("R2")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.purple)
                        }
                    }
                }
            }
            
            // Section 5: AI Models & Queues
            if let ai = currentConfig?.aiBindings, !ai.isEmpty {
                Section(header: Text("AI Bindings (\(ai.count))")) {
                    ForEach(Array(ai.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.body.weight(.medium))
                            Spacer()
                            Text("AI")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.pink)
                        }
                    }
                }
            }
            
            // Section 6: Compatibility
            Section(header: Text("Compatibility Settings")) {
                HStack {
                    Text("Compatibility Date")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(currentConfig?.compatibilityDate ?? "Default")
                        .font(.body.monospacedDigit())
                }
                
                if let flags = currentConfig?.compatibilityFlags, !flags.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Compatibility Flags")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(flags.joined(separator: ", "))
                            .font(.caption.monospaced())
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Bindings & Variables")
        .navigationBarTitleDisplayMode(.inline)
        .toastContainer()
    }
}
