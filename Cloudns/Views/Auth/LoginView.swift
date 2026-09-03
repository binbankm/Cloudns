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
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.subheadline.weight(.semibold))
                                Text("Introduction")
                                    .font(.subheadline.weight(.medium))
                            }
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color(.tertiarySystemFill))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            HIGFeedback.impact(.light)
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(8)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 4)
                
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
                                    .higTouchTarget(36)
                                    .accessibilityLabel("Clear email")
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
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
                                            HIGFeedback.copied()
                                        }
                                    }
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.orange)
                                    .higTouchTarget(36)
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
                                    HIGFeedback.toggled()
                                } label: {
                                    Image(systemName: isShowingApiKey ? "eye.slash.fill" : "eye.fill")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .buttonStyle(.plain)
                                .higTouchTarget(36)
                                .accessibilityLabel(isShowingApiKey ? "Hide API key" : "Show API key")
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(focusedField == .apiKey ? Color.orange : Color.clear, lineWidth: 1.5)
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
                                        : [themeManager.currentColor.color, themeManager.currentColor.color.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: isButtonDisabled ? Color.clear : themeManager.currentColor.color.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.higPressable)
                        .disabled(isButtonDisabled)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
