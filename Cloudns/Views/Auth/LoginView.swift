import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    // Manage keyboard focus
    enum Field {
        case email
        case apiKey
    }
    @FocusState private var focusedField: Field?
    
    var onLoginSuccess: (() -> Void)?
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer(minLength: 12)
                
                // 1. Logo and Title Area
                VStack(spacing: 12) {
                    Image(systemName: "cloud.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .foregroundStyle(.orange)
                        .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                        .accessibilityHidden(true)
                    
                    VStack(spacing: 6) {
                        Text(onLoginSuccess == nil ? "Welcome Back" : "Add Account")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                        
                        Text(onLoginSuccess == nil ? "Manage your domains with ease." : "Enter your Cloudflare credentials.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 24)
                
                // 2. Input Fields
                VStack(spacing: 18) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundStyle(.gray)
                                .accessibilityHidden(true)
                            TextField("Enter your email", text: $viewModel.email)
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
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .email ? Color.orange : Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // API Key Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Global API Key")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Image(systemName: "key")
                                .foregroundStyle(.gray)
                                .accessibilityHidden(true)
                            SecureField("Enter your Global API Key", text: $viewModel.apiKey)
                                .textContentType(.password)
                                .keyboardType(.asciiCapable)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .apiKey)
                                .submitLabel(.done)
                                .disabled(viewModel.isLoading)
                                .onSubmit {
                                    focusedField = nil
                                    Task {
                                        await viewModel.login(onSuccess: onLoginSuccess)
                                    }
                                }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .apiKey ? Color.orange : Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    Text(LocalizedStringKey(errorMessage))
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                        .padding(.horizontal, 24)
                        .onAppear {
                            HapticManager.notification(.error)
                        }
                }
                
                // 3. Login Button
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
                            Text("Log In")
                                .font(.body.weight(.semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 24)
                .padding(.horizontal, 24)
                .disabled(isButtonDisabled)
                
                Spacer(minLength: 16)
                
                // 4. Footer
                VStack(spacing: 12) {
                    Button(action: {
                        if let url = URL(string: "https://dash.cloudflare.com/profile/api-tokens") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Forgot your API key?")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        VStack { Divider() }
                        Text("or")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                        VStack { Divider() }
                    }
                    .padding(.horizontal, 60)
                    
                    Button(action: {
                        if let url = URL(string: "https://dash.cloudflare.com/sign-up") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundStyle(.secondary)
                            Text("Sign Up")
                                .foregroundStyle(.orange)
                                .fontWeight(.medium)
                        }
                        .font(.footnote)
                    }
                }
                .padding(.bottom, 16)
            }
            .centerConstrainedWidth(maxWidth: 500)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 15, coordinateSpace: .local)
                    .onChanged { value in
                        if value.translation.height > 15 {
                            focusedField = nil
                        }
                    }
            )
            .onTapGesture {
                focusedField = nil
            }
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
