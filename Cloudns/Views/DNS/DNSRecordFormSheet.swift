import SwiftUI

// MARK: - DNSRecordFormSheet (Gentle Half-Sheet DNS Form)

struct DNSRecordFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: DNSRecordFormViewModel

    let onRecordSaved: (DNSRecord) -> Void

    init(
        zone: Zone,
        existingRecord: DNSRecord? = nil,
        onRecordSaved: @escaping (DNSRecord) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: DNSRecordFormViewModel(
                zone: zone,
                existingRecord: existingRecord
            )
        )
        self.onRecordSaved = onRecordSaved
    }

    private var contentPlaceholder: String {
        switch viewModel.selectedType {
        case .a:
            "192.0.2.1"
        case .aaaa:
            "2001:db8::1"
        case .cname:
            "target.example.com"
        case .txt:
            "v=spf1 include:_spf.example.com ~all"
        case .mx:
            "mail.example.com"
        case .ns:
            "ns1.example.com"
        default:
            "192.0.2.1"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: GentleSpacing.lg) {
                    // MARK: - Section 1: Record Type Pill Selector

                    typeSelectionSection

                    // MARK: - Section 2: Name and Content Card

                    nameAndContentSection

                    // MARK: - Section 3: Proxy Status (if proxiable)

                    if viewModel.supportsProxy {
                        proxySection
                    }

                    // MARK: - Section 4: TTL and Additional Parameters

                    ttlAndPrioritySection

                    // MARK: - Section 5: Optional Comments

                    commentSection

                    // MARK: - Error Callout

                    if let error = viewModel.errorMessage {
                        GentleCallout(
                            message: error,
                            type: .danger
                        )
                    }

                    // MARK: - Submit Button

                    submitButton
                }
                .padding(GentleSpacing.lg)
            }
            .gentleKeyboardDismissable()
            .gentleCanvas()
            .navigationTitle(viewModel.isEditing ? "Edit Record" : "Add Record")
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
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Type Selector

    private var typeSelectionSection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.sm) {
            Text("Type")
                .font(GentleTypography.subheadlineBold)
                .foregroundStyle(GentleColor.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: GentleSpacing.xs) {
                    ForEach(DNSRecordType.allCases) { type in
                        let isSelected = viewModel.selectedType == type
                        Button {
                            viewModel.onTypeChanged(type)
                            GentleHaptics.selection()
                        } label: {
                            Text(type.rawValue)
                                .font(GentleTypography.captionSmall)
                                .fontWeight(isSelected ? .bold : .medium)
                                .padding(.horizontal, GentleSpacing.sm)
                                .padding(.vertical, GentleSpacing.xs)
                                .foregroundStyle(isSelected ? GentleColor.textOnAccent : GentleColor.textPrimary)
                                .background(isSelected ? GentleColor.accent : GentleColor.cardSurfaceSecondary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .gentleCardStyle(cornerRadius: GentleCornerRadius.card, padding: GentleSpacing.lg)
    }

    // MARK: - Name and Content

    private var nameAndContentSection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.md) {
            // Name Field
            VStack(alignment: .leading, spacing: GentleSpacing.xxs) {
                Text("Name")
                    .font(GentleTypography.subheadlineBold)
                    .foregroundStyle(GentleColor.textPrimary)

                GentleTextField(
                    String(localized: "@ or subdomain"),
                    text: $viewModel.name,
                    leadingIcon: "globe",
                    isMonospaced: true,
                    keyboardType: .URL,
                    autocapitalization: .never,
                    disableAutocorrection: true
                )

                Text("Use @ for root domain, or enter subdomain (e.g. api)")
                    .font(GentleTypography.caption)
                    .foregroundStyle(GentleColor.textSecondary)
            }

            GentleDivider()

            // Content Field
            VStack(alignment: .leading, spacing: GentleSpacing.xxs) {
                Text("Content")
                    .font(GentleTypography.subheadlineBold)
                    .foregroundStyle(GentleColor.textPrimary)

                GentleTextField(
                    contentPlaceholder,
                    text: $viewModel.content,
                    leadingIcon: "arrow.right.circle",
                    isMonospaced: true,
                    keyboardType: .URL,
                    autocapitalization: .never,
                    disableAutocorrection: true
                )
            }
        }
        .gentleCardStyle(cornerRadius: GentleCornerRadius.card, padding: GentleSpacing.lg)
    }

    // MARK: - Proxy Section

    private var proxySection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: GentleSpacing.micro) {
                    HStack(spacing: GentleSpacing.xs) {
                        Image(systemName: viewModel.proxied ? "cloud.fill" : "cloud")
                            .foregroundStyle(viewModel.proxied ? GentleColor.statusProxied : GentleColor.textSecondary)
                        Text("Proxy Status")
                            .font(GentleTypography.cardTitle)
                            .foregroundStyle(GentleColor.textPrimary)
                    }

                    Text("Accelerates web traffic and hides origin IP.")
                        .font(GentleTypography.caption)
                        .foregroundStyle(GentleColor.textSecondary)
                }

                Spacer()

                Toggle(isOn: $viewModel.proxied) {
                    EmptyView()
                }
                .labelsHidden()
                .tint(GentleColor.statusProxied)
            }
        }
        .gentleCardStyle(cornerRadius: GentleCornerRadius.card, padding: GentleSpacing.lg)
    }

    // MARK: - TTL & Priority

    private var ttlAndPrioritySection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.md) {
            // TTL Row
            HStack {
                Text("TTL")
                    .font(GentleTypography.subheadlineBold)
                    .foregroundStyle(GentleColor.textPrimary)

                Spacer()

                if viewModel.proxied {
                    Text("Auto (Managed by Proxy)")
                        .font(GentleTypography.footnote)
                        .foregroundStyle(GentleColor.textSecondary)
                } else {
                    Menu {
                        ForEach(DNSTTLOption.commonOptions) { opt in
                            Button(opt.displayName) {
                                viewModel.ttl = opt.seconds
                                GentleHaptics.selection()
                            }
                        }
                    } label: {
                        HStack(spacing: GentleSpacing.xxs) {
                            Text(currentTTLDisplayName)
                                .font(GentleTypography.bodyMedium)
                                .foregroundStyle(GentleColor.accent)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(GentleTypography.captionSmall)
                                .foregroundStyle(GentleColor.textSecondary)
                        }
                        .padding(.horizontal, GentleSpacing.sm)
                        .padding(.vertical, GentleSpacing.xs)
                        .background(GentleColor.cardSurfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: GentleCornerRadius.md, style: .continuous))
                    }
                }
            }

            // Priority Row (for MX / SRV)
            if viewModel.requiresPriority {
                GentleDivider()

                VStack(alignment: .leading, spacing: GentleSpacing.xxs) {
                    Text("Priority")
                        .font(GentleTypography.subheadlineBold)
                        .foregroundStyle(GentleColor.textPrimary)

                    GentleTextField(
                        "10",
                        text: $viewModel.priority,
                        leadingIcon: "flag",
                        isMonospaced: true,
                        keyboardType: .numberPad
                    )
                }
            }
        }
        .gentleCardStyle(cornerRadius: GentleCornerRadius.card, padding: GentleSpacing.lg)
    }

    private var currentTTLDisplayName: String {
        DNSTTLOption.commonOptions.first(where: { $0.seconds == viewModel.ttl })?.displayName ?? "\(viewModel.ttl)s"
    }

    // MARK: - Comment

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.xxs) {
            Text("Comment (Optional)")
                .font(GentleTypography.subheadlineBold)
                .foregroundStyle(GentleColor.textPrimary)

            GentleTextField(
                String(localized: "Notes or description"),
                text: $viewModel.comment,
                leadingIcon: "text.bubble"
            )
        }
        .gentleCardStyle(cornerRadius: GentleCornerRadius.card, padding: GentleSpacing.lg)
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            hideKeyboard()
            Task {
                do {
                    let record = try await viewModel.submit()
                    onRecordSaved(record)
                    dismiss()
                } catch {
                    // Handled in viewModel
                }
            }
        } label: {
            HStack(spacing: GentleSpacing.xs) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(GentleColor.textOnAccent)
                        .padding(.trailing, GentleSpacing.xxs)
                    Text("Saving...")
                } else {
                    Text(viewModel.isEditing ? "Save Changes" : "Save Record")
                }
            }
        }
        .buttonStyle(GentlePrimaryButtonStyle())
        .disabled(!viewModel.canSubmit)
        .padding(.top, GentleSpacing.sm)
    }
}
