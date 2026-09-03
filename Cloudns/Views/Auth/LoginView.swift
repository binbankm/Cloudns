import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppStorageKey.hasSeenOnboarding) private var hasSeenOnboarding = true
    
    @StateObject private var viewModel = LoginViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Manage keyboard focus
    enum Field {
        case email
        case apiKey
    }
    @FocusState private var focusedField: Field?
    @State private var isShowingApiKey = false
    
    var onLoginSuccess: (() -> Void)?
    
    var body: some View {
        ZStack {
            // 1. Ambient Aurora Background
            Color(.systemGroupedBackground)
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
            
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    if onLoginSuccess == nil {
                        Button {
                            HIGFeedback.impact(.light)
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                hasSeenOnboarding = false
                            }
                        } label: {
                            HStack(spacing: HIGTokens.Spacing.xs) {
                                Image(systemName: "chevron.left")
                                    .font(HIGTypography.subheadline.weight(.semibold))
                                Text("Introduction")
                                    .font(HIGTypography.subheadline.weight(.medium))
                            }
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, HIGTokens.Spacing.md)
                            .padding(.vertical, HIGTokens.Spacing.xs + 3)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .higTouchTarget()
                    } else {
                        Button {
                            HIGFeedback.impact(.light)
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(HIGTypography.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(HIGTokens.Spacing.sm)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .higTouchTarget()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, HIGTokens.Spacing.xl)
                .padding(.top, HIGTokens.Spacing.md)
                .padding(.bottom, HIGTokens.Spacing.xs)
                
                ScrollView {
                    VStack(spacing: 20) {
                        Spacer(minLength: 12)
                    
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
                                .fill(Color(.secondarySystemGroupedBackground))
                                .frame(width: 76, height: 76)
                                .shadow(color: Color.orange.opacity(0.2), radius: 14, x: 0, y: 6)
                                .overlay(
                                    Circle()
                                        .stroke(Color.orange.opacity(0.25), lineWidth: 1.5)
                                )
                            
                            Image(systemName: "cloud.fill")
                                .font(.largeTitle.weight(.semibold))
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
                        
                        VStack(spacing: HIGTokens.Spacing.xs) {
                            Text(onLoginSuccess == nil ? "Welcome to Cloudns" : "Add Account")
                                .font(HIGTypography.title2)
                                .foregroundStyle(.primary)
                            
                            Text(onLoginSuccess == nil ? "Connect your Cloudflare API to manage edge fleets." : "Enter your Cloudflare credentials.")
                                .font(HIGTypography.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, HIGTokens.Spacing.xxl)
                        }
                    }
                    .padding(.bottom, HIGTokens.Spacing.xs)
                    
                    // 3. Frosted Credentials Card
                    VStack(spacing: HIGTokens.Spacing.lg) {
                        // Email Field
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
                            Text("Account Email")
                                .font(HIGTypography.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: HIGTokens.Spacing.md) {
                                Image(systemName: "envelope.fill")
                                    .font(HIGTypography.subheadline)
                                    .foregroundStyle(focusedField == .email ? Color.higAccent : .gray)
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
                                    .higTouchTarget()
                                    .accessibilityLabel("Clear email")
                                }
                            }
                            .padding(.horizontal, HIGTokens.Spacing.md)
                            .padding(.vertical, HIGTokens.Spacing.md)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous)
                                    .stroke(focusedField == .email ? Color.higAccent : Color.clear, lineWidth: 1.5)
                            )
                        }
                        
                        // API Key Field
                        VStack(alignment: .leading, spacing: HIGTokens.Spacing.xs) {
                            HStack {
                                Text("Global API Key")
                                    .font(HIGTypography.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                if viewModel.apiKey.isEmpty {
                                    Button("Paste") {
                                        if let clip = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                                            viewModel.apiKey = clip
                                            HIGFeedback.copied()
                                        }
                                    }
                                    .font(HIGTypography.caption2.weight(.semibold))
                                    .foregroundStyle(Color.higAccent)
                                    .higTouchTarget()
                                }
                            }
                            
                            HStack(spacing: HIGTokens.Spacing.md) {
                                Image(systemName: "key.fill")
                                    .font(HIGTypography.subheadline)
                                    .foregroundStyle(focusedField == .apiKey ? Color.higAccent : .gray)
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
                                    HIGFeedback.toggled()
                                } label: {
                                    Image(systemName: isShowingApiKey ? "eye.slash.fill" : "eye.fill")
                                        .font(HIGTypography.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .buttonStyle(.plain)
                                .higTouchTarget()
                                .accessibilityLabel(isShowingApiKey ? "Hide API key" : "Show API key")
                            }
                            .padding(.horizontal, HIGTokens.Spacing.md)
                            .padding(.vertical, HIGTokens.Spacing.md)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous)
                                    .stroke(focusedField == .apiKey ? Color.higAccent : Color.clear, lineWidth: 1.5)
                            )
                        }
                        
                        // Error Message Banner
                        if let errorMessage = viewModel.errorMessage {
                            HStack(spacing: HIGTokens.Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(HIGColors.error)
                                Text(LocalizedStringKey(errorMessage))
                                    .font(HIGTypography.caption.weight(.medium))
                                    .foregroundStyle(HIGColors.error)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(HIGTokens.Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(HIGColors.error.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.md, style: .continuous))
                            .onAppear {
                                HIGFeedback.error()
                            }
                        }
                        
                        // Login Action Button
                        let isFormValid = !viewModel.email.isEmpty && !viewModel.apiKey.isEmpty
                        let isButtonDisabled = viewModel.isLoading || !isFormValid
                        
                        Button(action: {
                            focusedField = nil
                            HIGFeedback.impact(.medium)
                            Task {
                                await viewModel.login(onSuccess: onLoginSuccess)
                            }
                        }) {
                            Group {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    HStack(spacing: HIGTokens.Spacing.xs) {
                                        Text("Log In to Dashboard")
                                            .font(HIGTypography.body.weight(.semibold))
                                        Image(systemName: "arrow.right")
                                            .font(HIGTypography.caption.weight(.bold))
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
                                        : [themeManager.currentColor.color, themeManager.currentColor.color.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.card, style: .continuous))
                            .shadow(color: isButtonDisabled ? Color.clear : themeManager.currentColor.color.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.higPressable)
                        .disabled(isButtonDisabled)
                    }
                    .padding(HIGTokens.Spacing.lg)
                    .background(Color.higCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: HIGTokens.Radius.lg, style: .continuous))
                    .padding(.horizontal, HIGTokens.Spacing.lg)
                    
                    // 4. Helper Links & Guide
                    VStack(spacing: HIGTokens.Spacing.md) {
                        Button(action: {
                            if let url = URL(string: "https://dash.cloudflare.com/profile/api-tokens") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: HIGTokens.Spacing.xs) {
                                Image(systemName: "questionmark.circle")
                                    .font(HIGTypography.caption)
                                Text("Where to find your Global API Key?")
                                    .font(HIGTypography.caption.weight(.medium))
                            }
                            .foregroundStyle(Color.higAccent)
                        }
                        .higTouchTarget()
                        
                        // Apple Keychain Security Seal
                        HStack(spacing: HIGTokens.Spacing.xs) {
                            Image(systemName: "lock.shield.fill")
                                .font(HIGTypography.caption2)
                                .foregroundStyle(.secondary)
                            Text("Protected by Apple Keychain Isolation")
                                .font(HIGTypography.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, HIGTokens.Spacing.xs)
                    }
                    .padding(.bottom, HIGTokens.Spacing.xxl)
                }
            }
            .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = nil
                }
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

#Preview {
    LoginView()
}
