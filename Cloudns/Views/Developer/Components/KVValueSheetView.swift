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
                    HStack {
                        Text("KEY:")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(keyName)
                            .font(.caption.monospaced())
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView("Loading value...")
                            Spacer()
                        }
                        .padding(.vertical, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("VALUE CONTENT")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = valueText
                                    HapticManager.impact(.light)
                                    ToastManager.shared.showCopied("Value copied")
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .font(.caption)
                                }
                            }
                            
                            Text(valueText)
                                .font(.footnote.monospaced())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("KV Value Inspector")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .toastContainer()
        }
    }
}
