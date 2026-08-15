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
                    .foregroundColor(.orange)
                    .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 8) {
                    Text(onLoginSuccess == nil ? "Welcome Back" : "Add Account")
                        .font(.title)
                        .foregroundColor(.primary)
                    
                    Text(onLoginSuccess == nil ? "Manage your domains with ease." : "Enter your Cloudflare credentials.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.gray)
                            .accessibilityHidden(true)
                        TextField("Enter your email", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .disabled(viewModel.isLoading)
                            .onSubmit {
                                focusedField = .apiKey
                            }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
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
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "key")
                            .foregroundColor(.gray)
                            .accessibilityHidden(true)
                        SecureField("Enter your Global API Key", text: $viewModel.apiKey)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
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
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
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
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
                    .accessibilityLabel(errorMessage)
                    .onAppear {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
                    }
            }
            
            // Login Button
            let isFormValid = !viewModel.email.isEmpty && !viewModel.apiKey.isEmpty
            let isButtonDisabled = viewModel.isLoading || !isFormValid
            
            Button(action: {
                focusedField = nil // Dismiss keyboard
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                Task {
                    await viewModel.login(onSuccess: onLoginSuccess)
                }
            }) {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Log In")
                            .font(.body)
                    }
                }
                .foregroundColor(isButtonDisabled ? .gray : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isButtonDisabled ? Color.gray.opacity(0.2) : Color.orange)
                .cornerRadius(12)
                .shadow(color: isButtonDisabled ? .clear : .orange.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)
            .disabled(isButtonDisabled)
            
            Spacer().frame(height: 40) // Fixed gap instead of taking all remaining space
            
            // Footer
            VStack(spacing: 16) {
                Button(action: {
                    if let url = URL(string: "https://dash.cloudflare.com/profile/api-tokens") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Forgot your API key?")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    VStack { Divider() }
                    Text("or")
                        .font(.footnote)
                        .foregroundColor(.secondary)
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
                            .foregroundColor(.secondary)
                        Text("Sign Up")
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                    .font(.footnote)
                }
            }
            
            Spacer()
        }
        .background(
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    focusedField = nil
                }
        )
    }
}

#Preview {
    LoginView()
}
