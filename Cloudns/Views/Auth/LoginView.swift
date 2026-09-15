import SwiftUI

// MARK: - LoginView (Warm, Cozy & Pure Global API Key Authentication)

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case email
        case apiKey
        case accountName
    }

    init(viewModel: LoginViewModel = LoginViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: GentleSpacing.xxl) {
                    // MARK: - Brand & Welcome Header

                    VStack(spacing: GentleSpacing.sm) {
                        ZStack {
                            Circle()
                                .fill(GentleColor.accent.opacity(0.12))
                                .frame(width: 80, height: 80)

                            Image(systemName: "cloud.sun.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundStyle(GentleColor.accent)
                        }
                        .padding(.top, GentleSpacing.xl)

                        Text("Cloudns")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(GentleColor.textPrimary)

                        Text("Native Cloudflare Client")
                            .font(GentleTypography.body)
                            .foregroundStyle(GentleColor.textSecondary)
                    }

                    // MARK: - Authentication Form Card

                    VStack(alignment: .leading, spacing: GentleSpacing.lg) {
                        // Email Field
                        VStack(alignment: .leading, spacing: GentleSpacing.xs) {
                            Text("Email")
                                .font(GentleTypography.subheadlineBold)
                                .foregroundStyle(GentleColor.textPrimary)

                            GentleTextField(
                                "name@example.com",
                                text: $viewModel.email,
                                leadingIcon: "envelope.fill",
                                keyboardType: .emailAddress,
                                autocapitalization: .never,
                                disableAutocorrection: true,
                                onCommit: {
                                    focusedField = .apiKey
                                }
                            )
                            .focused($focusedField, equals: .email)
                        }

                        // Global API Key Field
                        VStack(alignment: .leading, spacing: GentleSpacing.xs) {
                            HStack {
                                Text("Global API Key")
                                    .font(GentleTypography.subheadlineBold)
                                    .foregroundStyle(GentleColor.textPrimary)

                                Spacer()

                                Button {
                                    if let clipboardString = UIPasteboard.general.string {
                                        viewModel.setApiKey(clipboardString)
                                        GentleHaptics.soft()
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.clipboard")
                                            .font(GentleTypography.caption)
                                        Text("Paste")
                                            .font(GentleTypography.caption)
                                    }
                                    .foregroundStyle(GentleColor.accent)
                                }
                            }

                            GentleTextField(
                                "37-character API key",
                                text: $viewModel.apiKey,
                                leadingIcon: "key.fill",
                                isSecure: true,
                                isMonospaced: true,
                                autocapitalization: .never,
                                disableAutocorrection: true,
                                onCommit: {
                                    focusedField = .accountName
                                }
                            )
                            .focused($focusedField, equals: .apiKey)

                            // Key character length hint
                            HStack {
                                Spacer()
                                Text("\(viewModel.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).count)/37")
                                    .font(GentleTypography.caption)
                                    .foregroundStyle(
                                        viewModel.isApiKeyValid
                                            ? GentleColor.statusActive
                                            : GentleColor.textSecondary.opacity(0.6)
                                    )
                                    .monospacedDigit()
                            }
                        }

                        // Account Alias (Optional)
                        VStack(alignment: .leading, spacing: GentleSpacing.xs) {
                            Text("Account Alias (Optional)")
                                .font(GentleTypography.subheadlineBold)
                                .foregroundStyle(GentleColor.textPrimary)

                            GentleTextField(
                                "e.g. Production, Personal",
                                text: $viewModel.accountName,
                                leadingIcon: "tag.fill",
                                onCommit: {
                                    focusedField = nil
                                    if viewModel.canSubmit {
                                        Task { await viewModel.login() }
                                    }
                                }
                            )
                            .focused($focusedField, equals: .accountName)
                        }

                        // Error message banner
                        if let error = viewModel.errorMessage {
                            HStack(spacing: GentleSpacing.sm) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(GentleColor.statusDanger)
                                    .font(GentleTypography.subheadline)

                                Text(error)
                                    .font(GentleTypography.footnote)
                                    .foregroundStyle(GentleColor.statusDanger)
                                    .lineSpacing(2)
                            }
                            .padding(GentleSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(GentleColor.statusDanger.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: GentleCornerRadius.md, style: .continuous))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Submit Button
                        Button {
                            focusedField = nil
                            Task {
                                await viewModel.login()
                            }
                        } label: {
                            if viewModel.state.isLoading {
                                HStack(spacing: GentleSpacing.sm) {
                                    ProgressView()
                                        .tint(Color.white)
                                    Text("Verifying...")
                                }
                            } else {
                                HStack(spacing: GentleSpacing.xs) {
                                    Image(systemName: "arrow.right.circle.fill")
                                    Text("Connect Account")
                                }
                            }
                        }
                        .buttonStyle(GentlePrimaryButtonStyle())
                        .disabled(!viewModel.canSubmit)
                        .padding(.top, GentleSpacing.xs)
                    }
                    .gentleCardStyle(cornerRadius: GentleCornerRadius.card, padding: GentleSpacing.xl)

                    // MARK: - Help & Guide Link

                    Button {
                        viewModel.showGuideSheet = true
                        GentleHaptics.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "questionmark.circle")
                            Text("Where is my Global API Key?")
                        }
                        .font(GentleTypography.subheadline)
                        .foregroundStyle(GentleColor.accent)
                    }
                    .padding(.bottom, GentleSpacing.xl)
                }
                .padding(.horizontal, GentleSpacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
            .gentleCanvas()
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            .sheet(isPresented: $viewModel.showGuideSheet) {
                ApiKeyGuideSheet()
            }
            .onChange(of: viewModel.state) { newState in
                switch newState {
                case .loaded:
                    GentleHaptics.light()
                case .error:
                    GentleHaptics.warning()
                default:
                    break
                }
            }
        }
    }

    // MARK: - Private Helpers

    private func hideKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

#Preview {
    LoginView()
}
