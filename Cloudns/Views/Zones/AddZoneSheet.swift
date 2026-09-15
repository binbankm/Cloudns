import SwiftUI

// MARK: - AddZoneSheet (Gentle Domain Binding Drawer)

struct AddZoneSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddZoneViewModel()

    let onZoneCreated: (Zone) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: GentleSpacing.lg) {
                    // Section 1: Domain Name Input Card
                    VStack(alignment: .leading, spacing: GentleSpacing.sm) {
                        Text("Domain Name")
                            .font(GentleTypography.subheadlineBold)
                            .foregroundStyle(GentleColor.textPrimary)

                        GentleTextField(
                            "example.com",
                            text: $viewModel.domainName,
                            leadingIcon: "globe",
                            isMonospaced: true,
                            keyboardType: .URL,
                            autocapitalization: .never,
                            disableAutocorrection: true
                        )

                        Text("Apex domain without protocol or path (e.g. example.com)")
                            .font(GentleTypography.caption)
                            .foregroundStyle(GentleColor.textSecondary)
                    }
                    .gentleCardStyle(cornerRadius: GentleCornerRadius.card, padding: GentleSpacing.lg)

                    // Section 2: DNS Jumpstart Configuration Card
                    VStack(alignment: .leading, spacing: GentleSpacing.md) {
                        HStack(alignment: .center, spacing: GentleSpacing.md) {
                            VStack(alignment: .leading, spacing: GentleSpacing.micro) {
                                Text("Scan DNS Records")
                                    .font(GentleTypography.cardTitle)
                                    .foregroundStyle(GentleColor.textPrimary)

                                Text("Automatically query and import existing DNS records.")
                                    .font(GentleTypography.caption)
                                    .foregroundStyle(GentleColor.textSecondary)
                            }

                            Spacer()

                            Toggle(isOn: $viewModel.jumpStart) {
                                EmptyView()
                            }
                            .labelsHidden()
                            .tint(GentleColor.accent)
                        }
                    }
                    .gentleCardStyle(cornerRadius: GentleCornerRadius.card, padding: GentleSpacing.lg)

                    // Error Callout if any
                    if let errorMessage = viewModel.errorMessage {
                        GentleCallout(
                            message: errorMessage,
                            type: .danger
                        )
                    }

                    // Action Button: Add Domain
                    Button {
                        submitDomain()
                    } label: {
                        HStack(spacing: GentleSpacing.xs) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(GentleColor.textOnAccent)
                                    .padding(.trailing, GentleSpacing.xxs)
                            }
                            if viewModel.isLoading {
                                Text("Adding...")
                            } else {
                                Text("Add Domain")
                            }
                        }
                    }
                    .buttonStyle(GentlePrimaryButtonStyle())
                    .disabled(!viewModel.canSubmit)
                    .padding(.top, GentleSpacing.sm)
                }
                .padding(GentleSpacing.lg)
            }
            .gentleKeyboardDismissable()
            .gentleCanvas()
            .navigationTitle("Add Domain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(GentleTypography.bodyMedium)
                    .foregroundStyle(GentleColor.textSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func submitDomain() {
        hideKeyboard()
        Task {
            do {
                let newZone = try await viewModel.createZone()
                onZoneCreated(newZone)
                dismiss()
            } catch {
                // Handled in viewModel
            }
        }
    }
}

#Preview {
    AddZoneSheet(onZoneCreated: { _ in })
}
