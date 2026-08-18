import SwiftUI

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
            // Section 1: Keys & Overview
            Section(header: Text("Widget Credentials")) {
                HStack {
                    Text("Widget Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(widget.name)
                        .font(.body.weight(.medium))
                }
                
                HStack {
                    Text("Mode")
                        .foregroundStyle(.secondary)
                    Spacer()
                    CloudnsBadge(.custom(color: .blue, text: (widget.mode ?? "Managed").capitalized), isCompact: true)
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
                            UIPasteboard.general.string = widget.sitekey
                            HapticManager.notification(.success)
                            ToastManager.shared.showCopied("Sitekey copied")
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
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
                                UIPasteboard.general.string = secret
                                HapticManager.notification(.success)
                                ToastManager.shared.showCopied("Secret Key copied")
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                
                if let domains = widget.domains, !domains.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
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
            
            // Section: Management Actions
            if viewModel != nil {
                Section(header: Text("Management")) {
                    Button {
                        HapticManager.impact(.light)
                        showingEditSheet = true
                    } label: {
                        Label("Edit Widget Settings", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        HapticManager.impact(.medium)
                        showingRotateAlert = true
                    } label: {
                        HStack {
                            Label("Rotate Secret Key", systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                            if isRotatingSecret {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isRotatingSecret)
                }
            }
            
            // Section 2: Code Integration Guide
            Section(header: Text("Integration Code Generator")) {
                Picker("Layer", selection: $selectedTab) {
                    Text("Client-side").tag("frontend")
                    Text("Server Verification").tag("backend")
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 2)
                .onChange(of: selectedTab) { _ in
                    HapticManager.impact(.light)
                }
                
                if selectedTab == "frontend" {
                    Picker("Framework", selection: $frontendFramework) {
                        Text("HTML / JS").tag("html")
                        Text("React / Next.js").tag("react")
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 2)
                    .onChange(of: frontendFramework) { _ in
                        HapticManager.impact(.light)
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
                        HapticManager.impact(.light)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(snippetCode)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.primary)
                            .padding(.vertical, 4)
                    }
                    
                    Button {
                        UIPasteboard.general.string = snippetCode
                        HapticManager.notification(.success)
                        ToastManager.shared.showCopied("Code copied")
                    } label: {
                        Label("Copy Code Snippet", systemImage: "doc.on.doc")
                            .font(.caption.weight(.semibold))
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .centerConstrainedWidth(maxWidth: 840)
        .navigationTitle(widget.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            if let vm = viewModel {
                EditTurnstileWidgetSheetView(viewModel: vm, widget: widget) { updated in
                    self.widget = updated
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
                HapticManager.impact(.medium)
                ToastManager.shared.showSuccess("Secret Rotated", message: "New secret key generated")
            } catch {
                ToastManager.shared.showError("Rotation Failed", message: error.localizedDescription)
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

struct EditTurnstileWidgetSheetView: View {
    @ObservedObject var viewModel: TurnstileViewModel
    let widget: TurnstileWidget
    var onUpdated: (TurnstileWidget) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var widgetName: String
    @State private var domainsText: String
    @State private var selectedMode: String
    @State private var isSubmitting = false
    
    private let modes = [
        ("managed", "Managed"),
        ("non-interactive", "Non-Interactive"),
        ("invisible", "Invisible")
    ]
    
    init(viewModel: TurnstileViewModel, widget: TurnstileWidget, onUpdated: @escaping (TurnstileWidget) -> Void) {
        self.viewModel = viewModel
        self.widget = widget
        self.onUpdated = onUpdated
        _widgetName = State(initialValue: widget.name)
        _domainsText = State(initialValue: widget.domains?.joined(separator: ", ") ?? "")
        _selectedMode = State(initialValue: widget.mode ?? "managed")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("General Information")) {
                    TextField("Widget Name", text: $widgetName)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                }
                
                Section(header: Text("Widget Mode")) {
                    Picker("Challenge Mode", selection: $selectedMode) {
                        ForEach(modes, id: \.0) { mode in
                            Text(mode.1).tag(mode.0)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Allowed Domains"), footer: Text("Hostnames allowed to use this widget.")) {
                    TextField("Domains (e.g. example.com, app.example.com)", text: $domainsText, axis: .vertical)
                        .lineLimit(2...4)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        submit()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(widgetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
        }
    }
    
    private func submit() {
        let name = widgetName.trimmingCharacters(in: .whitespacesAndNewlines)
        let domains = domainsText
            .split(separator: ",")
            .flatMap { $0.split(separator: "\n") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        isSubmitting = true
        Task {
            do {
                try await viewModel.updateWidget(sitekey: widget.sitekey, name: name, domains: domains.isEmpty ? ["*"] : domains, mode: selectedMode)
                let updated = TurnstileWidget(sitekey: widget.sitekey, name: name, mode: selectedMode, domains: domains.isEmpty ? ["*"] : domains, secret: widget.secret, createdOn: widget.createdOn, modifiedOn: widget.modifiedOn)
                onUpdated(updated)
                HapticManager.impact(.medium)
                ToastManager.shared.showSuccess("Widget Updated", message: name)
                dismiss()
            } catch {
                ToastManager.shared.showError("Update Failed", message: error.localizedDescription)
            }
            isSubmitting = false
        }
    }
}
