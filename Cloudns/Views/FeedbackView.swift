import SwiftUI
import Combine

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
        Timestamp: \(Date())
        """
    }
    
    var body: some View {
        Form {
            Section(header: Text("Feedback & Issue Description")) {
                TextEditor(text: $feedbackText)
                    .frame(minHeight: 120)
            }
            
            Section(header: Text("Environment Diagnostics"), footer: Text("Diagnostics info helps developers identify and resolve technical issues faster.")) {
                HStack {
                    Text("App Version")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("v\(appVersion) (\(buildNumber))")
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("iOS System")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("iOS \(systemVersion)")
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("Account")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(accountManager.activeEmail)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button {
                    UIPasteboard.general.string = diagnosticSummary
                    ToastManager.shared.showCopied("Diagnostics copied")
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Diagnostic Info")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            Section {
                Button {
                    if let url = URL(string: "https://github.com/binbankm/Cloudns/issues/new") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "ladybug.fill")
                        Text("Submit Issue on GitHub")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Feedback & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}
