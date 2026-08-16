import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    // Manage keyboard focus
    enum Field {
        case email
        case apiKey
    }
    @FocusState private var focusedField: Field?
    
    var onLoginSuccess: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo and Title Area
            VStack(spacing: 16) {
                Image(systemName: "cloud.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.orange)
                    .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                    .accessibilityHidden(true)
                
                VStack(spacing: 8) {
                    Text(onLoginSuccess == nil ? "Welcome Back" : "Add Account")
                        .font(.title)
                        .foregroundStyle(.primary)
                    
                    Text(onLoginSuccess == nil ? "Manage your domains with ease." : "Enter your Cloudflare credentials.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 40)
            
            // Input Fields
            VStack(spacing: 24) {
                // Email Field
                VStack(alignment: .leading, spacing: 8) {
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
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .disabled(viewModel.isLoading)
                            .onSubmit {
                                focusedField = .apiKey
                            }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(focusedField == .email ? Color.orange : Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                
                // API Key Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Global API Key")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Image(systemName: "key")
                            .foregroundStyle(.gray)
                            .accessibilityHidden(true)
                        SecureField("Enter your Global API Key", text: $viewModel.apiKey)
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
                    .padding()
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
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
                    .onAppear {
                        HapticManager.notification(.error)
                    }
            }
            
            // Login Button
            let isFormValid = !viewModel.email.isEmpty && !viewModel.apiKey.isEmpty
            let isButtonDisabled = viewModel.isLoading || !isFormValid
            
            Button(action: {
                focusedField = nil // Dismiss keyboard
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
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.top, 32)
            .padding(.horizontal, 24)
            .disabled(isButtonDisabled)
            
            Spacer().frame(height: 40)
            
            // Footer
            VStack(spacing: 16) {
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
            
            Spacer()
        }
        .background(
            Color(.systemBackground)
                .ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                }
        )
    }
}

#Preview {
    LoginView()
}
