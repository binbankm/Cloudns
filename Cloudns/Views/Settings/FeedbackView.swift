import SwiftUI
import Combine

// MARK: - FeedbackView
// Apple HIG Compliant Diagnostic Reporter & Feedback Hub

struct FeedbackView: View {
    @StateObject private var accountManager = AccountManager.shared
    @State private var feedbackText = ""
    @Environment(\.dismiss) private var dismiss
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var systemVersion: String {
        UIDevice.current.systemVersion
    }
    
    var deviceModel: String {
        UIDevice.current.model
    }
    
    var diagnosticSummary: String {
        """
        --- Cloudns Diagnostics ---
        App Version: v\(appVersion) (\(buildNumber))
        OS: iOS \(systemVersion)
        Device: \(deviceModel)
        Active Account: \(accountManager.activeEmail)
        Timestamp: \(DateFormatters.formatLocalDiagnosticTimestamp())
        """
    }
    
    var body: some View {
        Form {
            Section(header: Text("Feedback & Issue Description")) {
                TextEditor(text: $feedbackText)
                    .font(HIGTypography.body)
                    .frame(minHeight: 120)
            }
            
            Section(
                header: Text("Environment Diagnostics"),
                footer: Text("Diagnostics info helps developers identify and resolve technical issues faster.")
            ) {
                LabeledContent("App Version") {
                    Text("v\(appVersion) (\(buildNumber))")
                        .font(HIGTypography.subheadline.monospacedDigit())
                        .foregroundStyle(.primary)
                }
                
                LabeledContent("iOS System", value: "iOS \(systemVersion)")
                    .font(HIGTypography.body)
                
                LabeledContent("Account") {
                    Text(accountManager.activeEmail)
                        .font(HIGTypography.caption)
                        .foregroundStyle(.secondary)
                }
                
                LabeledContent("Local Time") {
                    Text(DateFormatters.formatLocalDiagnosticTimestamp())
                        .font(HIGTypography.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                
                Button {
                    UIPasteboard.general.string = diagnosticSummary
                    ToastManager.shared.showCopied("Diagnostic Summary Copied")
                    HIGFeedback.copied()
                } label: {
                    HStack(spacing: HIGTokens.Spacing.sm) {
                        Image(systemName: "doc.on.doc")
                            .font(HIGTypography.subheadline)
                        Text("Copy Diagnostic Info")
                            .font(HIGTypography.subheadline.weight(.medium))
                    }
                    .foregroundStyle(Color.higAccent)
                }
                .higTouchTarget(44)
            }
            
            Section {
                Button {
                    HIGFeedback.impact(.light)
                    if let url = URL(string: "https://github.com/binbankm/Cloudns/issues/new") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "ladybug.fill")
                        Text("Submit Issue on GitHub")
                            .font(HIGTypography.body.weight(.semibold))
                        Spacer()
                    }
                    .foregroundStyle(Color.higAccent)
                }
                .higTouchTarget(44)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Feedback & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}
