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
                        .fill(CloudnsColor.warningMuted)
                        .frame(width: w * 0.85, height: w * 0.85)
                        .blur(radius: 60)
                        .offset(x: -w * 0.2, y: -w * 0.35)
                    
                    Circle()
                        .fill(CloudnsColor.brand.opacity(0.08))
                        .frame(width: w * 0.75, height: w * 0.75)
                        .blur(radius: 65)
                        .offset(x: w * 0.3, y: w * 0.5)
                }
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: CloudnsSpacing.mdLarge) {
                    Spacer(minLength: CloudnsSpacing.md)
                    
                    // 2. Glowing Hero Logo & Header
                    VStack(spacing: CloudnsSpacing.mdSmall) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [CloudnsColor.brandAccent.opacity(0.3), CloudnsColor.brandAccent.opacity(0.0)],
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
                                .cloudnsShadow(.brand(color: CloudnsColor.brandAccent, radius: 14, y: 6))
                                .overlay(
                                    Circle()
                                        .stroke(CloudnsColor.brandAccent.opacity(0.25), lineWidth: 1.5)
                                )
                            
                            Image(systemName: "cloud.fill")
                                .font(.system(.largeTitle, design: .default, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .yellow],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cloudnsShadow(.brand(color: CloudnsColor.brandAccent, radius: 6, y: 2))
                        }
                        .frame(height: 80)
                        
                        VStack(spacing: CloudnsSpacing.xs) {
                            Text(onLoginSuccess == nil ? "Welcome to Cloudns" : "Add Account")
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .foregroundStyle(.primary)
                            
                            Text(onLoginSuccess == nil ? "Connect your Cloudflare API to manage edge fleets." : "Enter your Cloudflare credentials.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, CloudnsSpacing.lg)
                        }
                    }
                    .padding(.bottom, CloudnsSpacing.xs)
                    
                    // 3. Frosted Credentials Card
                    VStack(spacing: CloudnsSpacing.md) {
                        // Email Field
                        VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
                            Text("Account Email")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: CloudnsSpacing.smMd) {
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
                            .padding(.horizontal, CloudnsSpacing.mdMedium)
                            .padding(.vertical, CloudnsSpacing.mdSmall)
                            .background(CloudnsColor.tertiaryGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: CloudnsRadius.md)
                                    .stroke(focusedField == .email ? CloudnsColor.brandAccent : Color.clear, lineWidth: 1.5)
                            )
                        }
                        
                        // API Key Field
                        VStack(alignment: .leading, spacing: CloudnsSpacing.sm) {
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
                                    .foregroundStyle(CloudnsColor.brandAccent)
                                }
                            }
                            
                            HStack(spacing: CloudnsSpacing.smMd) {
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
                            .padding(.horizontal, CloudnsSpacing.mdMedium)
                            .padding(.vertical, CloudnsSpacing.mdSmall)
                            .background(CloudnsColor.tertiaryGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: CloudnsRadius.md)
                                    .stroke(focusedField == .apiKey ? CloudnsColor.brandAccent : Color.clear, lineWidth: 1.5)
                            )
                        }
                        
                        // Error Message Banner
                        if let errorMessage = viewModel.errorMessage {
                            HStack(spacing: CloudnsSpacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(CloudnsColor.danger)
                                Text(LocalizedStringKey(errorMessage))
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(CloudnsColor.danger)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(CloudnsSpacing.smMd)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(CloudnsColor.danger.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: CloudnsRadius.mdLg))
                            .onAppear {
                                HapticManager.notification(.error)
                            }
                        }
                        
                        // Login Action Button
                        let isFormValid = !viewModel.email.isEmpty && !viewModel.apiKey.isEmpty
                        
                        CloudnsButton(
                            "Log In to Dashboard",
                            icon: "arrow.right",
                            style: .primary(color: .orange),
                            size: .large,
                            isFullWidth: true,
                            isLoading: viewModel.isLoading,
                            disabled: !isFormValid
                        ) {
                            focusedField = nil
                            Task {
                                await viewModel.login(onSuccess: onLoginSuccess)
                            }
                        }
                    }
                    .padding(CloudnsSpacing.md)
                    .cloudnsCard(style: .frosted, size: .hero)
                    .padding(.horizontal, CloudnsSpacing.md)
                    
                    // 4. Helper Links & Guide
                    VStack(spacing: CloudnsSpacing.mdSmall) {
                        Button(action: {
                            if let url = URL(string: "https://dash.cloudflare.com/profile/api-tokens") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: CloudnsSpacing.xs) {
                                Image(systemName: "questionmark.circle")
                                    .font(.caption)
                                Text("Where to find your Global API Key?")
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(CloudnsColor.brandAccent)
                        }
                        
                        // Apple Keychain Security Seal
                        HStack(spacing: CloudnsSpacing.sm) {
                            Image(systemName: "lock.shield.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("Protected by Apple Keychain Isolation")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, CloudnsSpacing.xs)
                    }
                    .padding(.bottom, CloudnsSpacing.lg)
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
