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
                VStack(alignment: .leading, spacing: CloudnsSpacing.mdMedium) {
                    // 1. Key Name Header Card
                    HStack(spacing: CloudnsSpacing.mdSmall) {
                        Image(systemName: "key.horizontal.fill")
                            .font(.body)
                            .foregroundStyle(.purple)
                            .frame(width: CloudnsSize.iconHero, height: CloudnsSize.iconHero)
                            .background(Color.purple.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: CloudnsSpacing.xxs) {
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
                                .padding(CloudnsSpacing.sm)
                                .background(Color.purple.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.sm))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Copy Key Name")
                    }
                    .padding(CloudnsSpacing.mdSmall)
                    .background(CloudnsColor.secondaryGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md))
                    
                    // 2. Value Content Box
                    if isLoading {
                        VStack(spacing: CloudnsSpacing.mdSmall) {
                            ProgressView()
                                .scaleEffect(1.1)
                            Text("Loading value...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, CloudnsSpacing.xxl)
                    } else {
                        VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
                            HStack {
                                Text("VALUE CONTENT")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Text("\(valueText.utf8.count) bytes")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, CloudnsSpacing.sm)
                                    .padding(.vertical, CloudnsSpacing.xxs)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(Capsule())
                                
                                Button {
                                    UIPasteboard.general.string = valueText
                                    HapticManager.notification(.success)
                                    CloudnsToastManager.shared.showCopied("Value copied")
                                } label: {
                                    HStack(spacing: CloudnsSpacing.xs) {
                                        Image(systemName: "doc.on.doc")
                                        Text("Copy")
                                    }
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, CloudnsSpacing.smMd)
                                    .padding(.vertical, CloudnsSpacing.xs)
                                    .background(Color.purple)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Text(valueText)
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(CloudnsSpacing.mdMedium)
                                .background(CloudnsColor.secondaryGroupedBackground)
                                .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md))
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(CloudnsSpacing.md)
            }
            .background(CloudnsColor.groupedBackground)
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
