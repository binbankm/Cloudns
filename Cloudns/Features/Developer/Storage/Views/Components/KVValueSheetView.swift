import SwiftUI

// MARK: - KVValueSheetView

struct KVValueSheetView: View {
    // MARK: - Properties
    let keyName: String
    let valueText: String
    let isLoading: Bool
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
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
                            .clipShape(RoundedRectangle(cornerRadius: 8))
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
                            CloudnsToastManager.shared.showCopied("Key name copied")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.purple)
                                .padding(8)
                                .background(Color.purple.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Copy Key Name")
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // 2. Value Content Box
                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.1)
                            Text("Loading value...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 50)
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
                                    CloudnsToastManager.shared.showCopied("Value copied")
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
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("KV Value Inspector")
            .navigationBarTitleDisplayMode(.inline)
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
