import SwiftUI

// MARK: - KVValueSheetView

struct KVValueSheetView: View {
    let keyName: String
    let valueText: String
    let isLoading: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // 1. Key Name Header Card
                    HStack(spacing: 12) {
                        Image(systemName: "key.horizontal.fill")
                            .font(.body)
                            .foregroundStyle(.purple)
                            .frame(width: 36, height: 36)
                            .background(Color.purple.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("KEY NAME")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                            Text(keyName)
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                                .foregroundStyle(.primary)
                                .textSelection(.enabled)
                        }
                        
                        Spacer()
                        
                        Button {
                            UIPasteboard.general.string = keyName
                            HapticManager.notification(.success)
                            ToastManager.shared.showCopied("Key name copied")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.purple)
                                .padding(8)
                                .background(Color.purple.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Copy Key Name")
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                    // 2. Value Content Box
                    if isLoading {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("VALUE CONTENT")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            Text("Cloudflare KV Key Value Placeholder Payload\nKey configuration metadata\nEncrypted content")
                                .font(.subheadline.monospaced())
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .redacted(reason: .placeholder)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("VALUE CONTENT")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Text("\(valueText.utf8.count) bytes")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(Capsule())
                                
                                Button {
                                    UIPasteboard.general.string = valueText
                                    HapticManager.notification(.success)
                                    ToastManager.shared.showCopied("Value copied")
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.doc")
                                        Text("Copy")
                                    }
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.purple)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Text(valueText)
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("KV Value Inspector")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.purple)
                }
            }
            .toastContainer()
        }
    }
}
