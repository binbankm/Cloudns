import SwiftUI

// MARK: - TurnstileDetailView
// Apple HIG Compliant Cloudflare Turnstile Inspection, Key Rotation & Multi-Language Code Integration

struct TurnstileDetailView: View {
    @State var widget: TurnstileWidget
    var viewModel: TurnstileViewModel?
    
    @State private var selectedTab = "frontend"
    @State private var frontendFramework = "html"
    @State private var backendLang = "node"
    
    @State private var showingEditSheet = false
    @State private var showingRotateAlert = false
    @State private var isRotatingSecret = false
    @State private var currentSecret: String?
    
    init(widget: TurnstileWidget, viewModel: TurnstileViewModel? = nil) {
        _widget = State(initialValue: widget)
        self.viewModel = viewModel
        _currentSecret = State(initialValue: widget.secret)
    }
    
    var body: some View {
        List {
            // MARK: - Keys & Overview
            Section("Widget Credentials") {
                LabeledContent("Widget Name", value: widget.name)
                    .font(.body)
                
                LabeledContent("Mode") {
                    Text((widget.mode ?? "Managed").capitalized)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.blue.opacity(0.12)))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sitekey (Public)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Text(widget.sitekey)
                            .font(.caption.monospaced())
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Spacer()
                        Button {
                            copyToClipboard(widget.sitekey, toast: "Sitekey Copied")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
                
                if let secret = currentSecret, !secret.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Secret Key (Private)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Text(secret)
                                .font(.caption.monospaced())
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer()
                            Button {
                                copyToClipboard(secret, toast: "Secret Key Copied")
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                
                if let domains = widget.domains, !domains.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Allowed Domains")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(domains.joined(separator: ", "))
                            .font(.footnote)
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 2)
                }
            }
            
            // MARK: - Management Actions
            if viewModel != nil {
                Section("Management") {
                    Button {
                        HapticManager.impact(.light)
                        showingEditSheet = true
                    } label: {
                        Label("Edit Widget Settings", systemImage: "pencil")
                            .font(.body)
                    }
                    
                    Button(role: .destructive) {
                        HapticManager.impact(.medium)
                        showingRotateAlert = true
                    } label: {
                        HStack {
                            Label("Rotate Secret Key", systemImage: "arrow.triangle.2.circlepath")
                                .font(.body)
                            Spacer()
                            if isRotatingSecret {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isRotatingSecret)
                }
            }
            
            // MARK: - Code Integration Guide
            Section("Integration Code Generator") {
                Picker("Layer", selection: $selectedTab) {
                    Text("Client-side").tag("frontend")
                    Text("Server Verification").tag("backend")
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 2)
                .onChange(of: selectedTab) { _ in
                    HapticManager.selection()
                }
                
                if selectedTab == "frontend" {
                    Picker("Framework", selection: $frontendFramework) {
                        Text("HTML / JS").tag("html")
                        Text("React / Next.js").tag("react")
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 2)
                    .onChange(of: frontendFramework) { _ in
                        HapticManager.selection()
                    }
                } else {
                    Picker("Language", selection: $backendLang) {
                        Text("Node.js").tag("node")
                        Text("Python").tag("python")
                        Text("Go").tag("go")
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 2)
                    .onChange(of: backendLang) { _ in
                        HapticManager.selection()
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    ScrollView(.horizontal) {
                        Text(verbatim: snippetCode)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.primary)
                            .padding(.vertical, 2)
                    }
                    .scrollIndicators(.hidden)
                    
                    Button {
                        copyToClipboard(snippetCode, toast: "Code Snippet Copied")
                    } label: {
                        Label("Copy Code Snippet", systemImage: "doc.on.doc")
                            .font(.caption.weight(.semibold))
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(widget.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            Group {
                if let vm = viewModel {
                    EditTurnstileWidgetSheetView(viewModel: vm, widget: widget) { updated in
                        self.widget = updated
                    }
                }
            }
        }
        .alert("Rotate Secret Key", isPresented: $showingRotateAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Rotate & Invalidate Old Key", role: .destructive) {
                rotateSecret(invalidateImmediately: true)
            }
            Button("Rotate (Keep Old Key Valid)") {
                rotateSecret(invalidateImmediately: false)
            }
        } message: {
            Text("Rotating the secret key will generate a new secret key for backend token verification. Existing backend deployments using the old secret key might be affected.")
        }
    }
    
    private func rotateSecret(invalidateImmediately: Bool) {
        guard let vm = viewModel else { return }
        isRotatingSecret = true
        Task {
            do {
                let newSecret = try await vm.rotateSecret(sitekey: widget.sitekey, invalidateImmediately: invalidateImmediately)
                self.currentSecret = newSecret
                HapticManager.notification(.success)
                ToastManager.shared.showSuccess("Secret Key Rotated", icon: "key.fill")
            } catch {
                HapticManager.notification(.error)
            }
            isRotatingSecret = false
        }
    }
    
    private var snippetCode: String {
        if selectedTab == "frontend" {
            if frontendFramework == "html" {
                return """
                <!-- 1. Include Turnstile script in <head> -->
                <script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>

                <!-- 2. Place widget inside your <form> -->
                <form action="/login" method="POST">
                  <div class="cf-turnstile" data-sitekey="\(widget.sitekey)" data-theme="auto"></div>
                  <button type="submit">Submit</button>
                </form>
                """
            } else {
                return """
                // npm install @marsidev/react-turnstile
                import { Turnstile } from '@marsidev/react-turnstile';

                export default function LoginForm() {
                  return (
                    <form onSubmit={handleSubmit}>
                      <Turnstile
                        siteKey="\(widget.sitekey)"
                        onSuccess={(token) => setToken(token)}
                      />
                      <button type="submit">Log in</button>
                    </form>
                  );
                }
                """
            }
        } else {
            switch backendLang {
            case "node":
                return """
                // POST to Cloudflare Siteverify API
                const response = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                  body: new URLSearchParams({
                    secret: process.env.TURNSTILE_SECRET_KEY,
                    response: req.body['cf-turnstile-response'],
                    remoteip: req.ip
                  })
                });
                const outcome = await response.json();
                if (outcome.success) {
                  // Captcha verified!
                }
                """
            case "python":
                return """
                import requests, os

                verify_res = requests.post(
                    'https://challenges.cloudflare.com/turnstile/v0/siteverify',
                    data={
                        'secret': os.environ.get('TURNSTILE_SECRET_KEY'),
                        'response': token,
                        'remoteip': client_ip
                    }
                ).json()

                if verify_res.get('success'):
                    # Captcha token is valid
                """
            case "go":
                return """
                resp, err := http.PostForm("https://challenges.cloudflare.com/turnstile/v0/siteverify",
                    url.Values{
                        "secret":   {os.Getenv("TURNSTILE_SECRET_KEY")},
                        "response": {token},
                    })
                """
            default: return ""
            }
        }
    }
}

// MARK: - EditTurnstileWidgetSheetView (Inlined & Cohesive)

struct EditTurnstileWidgetSheetView: View {
    @ObservedObject var viewModel: TurnstileViewModel
    let widget: TurnstileWidget
    let onUpdated: (TurnstileWidget) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var domainsText: String
    @State private var mode: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    let modes = ["managed", "non-interactive", "invisible"]
    
    init(viewModel: TurnstileViewModel, widget: TurnstileWidget, onUpdated: @escaping (TurnstileWidget) -> Void) {
        self.viewModel = viewModel
        self.widget = widget
        self.onUpdated = onUpdated
        _name = State(initialValue: widget.name)
        _domainsText = State(initialValue: (widget.domains ?? []).joined(separator: ", "))
        _mode = State(initialValue: widget.mode ?? "managed")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Widget Details") {
                    TextField("Widget Name", text: $name)
                        .font(.body)
                        .submitLabel(.next)
                }
                
                Section {
                    TextField("example.com, app.example.com", text: $domainsText)
                        .font(.body.monospaced())
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Allowed Domains")
                } footer: {
                    Text("Comma or newline separated list of hostnames.")
                }
                
                Section("Challenge Mode") {
                    Picker("Mode", selection: $mode) {
                        ForEach(modes, id: \.self) { m in
                            Text(m.capitalized).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if let err = errorMessage {
                    Section {
                        Text(verbatim: err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Widget")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDragIndicator(.visible)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            errorMessage = nil
                            let domains = domainsText.components(separatedBy: CharacterSet(charactersIn: ",\n "))
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }
                            do {
                                try await viewModel.updateWidget(
                                    sitekey: widget.sitekey,
                                    name: name.trimmingCharacters(in: .whitespaces),
                                    domains: domains,
                                    mode: mode
                                )
                                let updated = TurnstileWidget(
                                    sitekey: widget.sitekey,
                                    name: name.trimmingCharacters(in: .whitespaces),
                                    mode: mode,
                                    domains: domains,
                                    secret: widget.secret,
                                    createdOn: widget.createdOn,
                                    modifiedOn: widget.modifiedOn
                                )
                                onUpdated(updated)
                                HapticManager.notification(.success)
                                ToastManager.shared.showSuccess("Widget Updated", icon: "checkmark.shield.fill")
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                HapticManager.notification(.error)
                            }
                            isSaving = false
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}
