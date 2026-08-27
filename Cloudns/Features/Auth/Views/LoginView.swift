import SwiftUI

struct LoginView: View {
    // MARK: - Properties
    @StateObject private var viewModel = LoginViewModel()
    
    // Manage keyboard focus
    enum Field {
        case email
        case apiKey
    }
    @FocusState private var focusedField: Field?
    @State private var isShowingApiKey = false
    
    var onLoginSuccess: (() -> Void)?
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // 1. Ambient Aurora Background
            CloudnsColor.groupedBackground
                .ignoresSafeArea()
            
            GeometryReader { proxy in
                let w = proxy.size.width
                
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: w * 0.85, height: w * 0.85)
                        .blur(radius: 60)
                        .offset(x: -w * 0.2, y: -w * 0.35)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.08))
                        .frame(width: w * 0.75, height: w * 0.75)
                        .blur(radius: 65)
                        .offset(x: w * 0.3, y: w * 0.5)
                }
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Spacer(minLength: 16)
                    
                    // 2. Glowing Hero Logo & Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.0)],
                                        center: .center,
                                        startRadius: 10,
                                        endRadius: 55
                                    )
                                )
                                .frame(width: 110, height: 110)
                                .blur(radius: 12)
                            
                            Circle()
                                .fill(CloudnsColor.secondaryGroupedBackground)
                                .frame(width: 76, height: 76)
                                .shadow(color: Color.orange.opacity(0.2), radius: 14, x: 0, y: 6)
                                .overlay(
                                    Circle()
                                        .stroke(Color.orange.opacity(0.25), lineWidth: 1.5)
                                )
                            
                            Image(systemName: "cloud.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .yellow],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .orange.opacity(0.4), radius: 6, x: 0, y: 2)
                        }
                        .frame(height: 80)
                        
                        VStack(spacing: 4) {
                            Text(onLoginSuccess == nil ? "Welcome to Cloudns" : "Add Account")
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .foregroundStyle(.primary)
                            
                            Text(onLoginSuccess == nil ? "Connect your Cloudflare API to manage edge fleets." : "Enter your Cloudflare credentials.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 4)
                    
                    // 3. Frosted Credentials Card
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Account Email")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 10) {
                                Image(systemName: "envelope.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(focusedField == .email ? .orange : .gray)
                                    .frame(width: 20)
                                
                                TextField("name@example.com", text: $viewModel.email)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.username)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .email)
                                    .submitLabel(.next)
                                    .disabled(viewModel.isLoading)
                                    .onSubmit {
                                        focusedField = .apiKey
                                    }
                                
                                if !viewModel.email.isEmpty && focusedField == .email {
                                    Button {
                                        viewModel.email = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.tertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(CloudnsColor.tertiaryGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: CloudnsRadius.md)
                                    .stroke(focusedField == .email ? Color.orange : Color.clear, lineWidth: 1.5)
                            )
                        }
                        
                        // API Key Field
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Global API Key")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                if viewModel.apiKey.isEmpty {
                                    Button("Paste") {
                                        if let clip = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                                            viewModel.apiKey = clip
                                            HapticManager.impact(.light)
                                        }
                                    }
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.orange)
                                }
                            }
                            
                            HStack(spacing: 10) {
                                Image(systemName: "key.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(focusedField == .apiKey ? .orange : .gray)
                                    .frame(width: 20)
                                
                                if isShowingApiKey {
                                    TextField("Enter Global API Key", text: $viewModel.apiKey)
                                        .keyboardType(.asciiCapable)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .apiKey)
                                        .submitLabel(.go)
                                        .disabled(viewModel.isLoading)
                                        .onSubmit {
                                            focusedField = nil
                                            Task {
                                                await viewModel.login(onSuccess: onLoginSuccess)
                                            }
                                        }
                                } else {
                                    SecureField("Enter Global API Key", text: $viewModel.apiKey)
                                        .textContentType(.none)
                                        .keyboardType(.asciiCapable)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .focused($focusedField, equals: .apiKey)
                                        .submitLabel(.go)
                                        .disabled(viewModel.isLoading)
                                        .onSubmit {
                                            focusedField = nil
                                            Task {
                                                await viewModel.login(onSuccess: onLoginSuccess)
                                            }
                                        }
                                }
                                
                                Button {
                                    isShowingApiKey.toggle()
                                    HapticManager.selection()
                                } label: {
                                    Image(systemName: isShowingApiKey ? "eye.slash.fill" : "eye.fill")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(CloudnsColor.tertiaryGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: CloudnsRadius.md)
                                    .stroke(focusedField == .apiKey ? Color.orange : Color.clear, lineWidth: 1.5)
                            )
                        }
                        
                        // Error Message Banner
                        if let errorMessage = viewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                Text(LocalizedStringKey(errorMessage))
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.smMd))
                            .onAppear {
                                HapticManager.notification(.error)
                            }
                        }
                        
                        // Login Action Button
                        let isFormValid = !viewModel.email.isEmpty && !viewModel.apiKey.isEmpty
                        let isButtonDisabled = viewModel.isLoading || !isFormValid
                        
                        Button(action: {
                            focusedField = nil
                            HapticManager.impact(.medium)
                            Task {
                                await viewModel.login(onSuccess: onLoginSuccess)
                            }
                        }) {
                            Group {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    HStack(spacing: 6) {
                                        Text("Log In to Dashboard")
                                            .font(.body.weight(.semibold))
                                        Image(systemName: "arrow.right")
                                            .font(.caption.weight(.bold))
                                    }
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                LinearGradient(
                                    colors: isButtonDisabled
                                        ? [Color.gray.opacity(0.4), Color.gray.opacity(0.5)]
                                        : [Color.orange, Color.orange.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md))
                            .shadow(color: isButtonDisabled ? Color.clear : Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isButtonDisabled)
                    }
                    .padding(16)
                    .cloudnsCard(style: .frosted, cornerRadius: 18)
                    .padding(.horizontal, 16)
                    
                    // 4. Helper Links & Guide
                    VStack(spacing: 12) {
                        Button(action: {
                            if let url = URL(string: "https://dash.cloudflare.com/profile/api-tokens") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "questionmark.circle")
                                    .font(.caption)
                                Text("Where to find your Global API Key?")
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(.orange)
                        }
                        
                        // Apple Keychain Security Seal
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("Protected by Apple Keychain Isolation")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.bottom, 24)
                }
                .centerConstrainedWidth(maxWidth: 480)
            }
            .scrollIndicators(.hidden)
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = nil
            }
        }
        .task {
            NetworkPreheater.warmup()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LoginView()
}
