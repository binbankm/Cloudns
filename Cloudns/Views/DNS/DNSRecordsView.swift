import SwiftUI

// MARK: - DNSRecordsView (Phase 4: DNS Core Engine Dashboard)

struct DNSRecordsView: View {
    @StateObject private var viewModel: DNSRecordsViewModel
    @State private var showAddSheet: Bool = false
    @State private var recordToEdit: DNSRecord?
    @State private var recordToDelete: DNSRecord?
    @State private var showDeleteConfirmation: Bool = false

    init(zone: Zone) {
        _viewModel = StateObject(wrappedValue: DNSRecordsViewModel(zone: zone))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: GentleSpacing.md) {
                // MARK: - Filter & Search Controls

                searchAndFilterSection

                // MARK: - ViewState Handling

                switch viewModel.state {
                case .idle, .loading:
                    loadingSkeletonView

                case .loaded:
                    loadedRecordsContent

                case let .empty(message):
                    GentleEmptyStateView(
                        iconName: "network",
                        title: "No Records",
                        message: message,
                        actionTitle: "Add Record",
                        action: {
                            showAddSheet = true
                        }
                    )
                    .padding(.top, GentleSpacing.xl)

                case let .error(message):
                    GentleErrorView(
                        message: message,
                        retryAction: {
                            Task { await viewModel.loadRecords() }
                        }
                    )
                    .padding(.top, GentleSpacing.xl)
                }

                Spacer(minLength: GentleSpacing.huge)
            }
            .padding(.horizontal, GentleSpacing.lg)
            .padding(.top, GentleSpacing.sm)
        }
        .gentleKeyboardDismissable()
        .gentleCanvas()
        .navigationTitle(viewModel.zone.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    GentleHaptics.light()
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(GentleTypography.subheadlineBold)
                        .foregroundStyle(GentleColor.accent)
                        .frame(width: GentleSpacing.xxl, height: GentleSpacing.xxl)
                        .background(GentleColor.cardSurface)
                        .clipShape(Circle())
                        .gentleSubtleShadow()
                }
            }
        }
        .refreshable {
            await viewModel.refreshRecords()
        }
        .task {
            await viewModel.loadRecords()
        }
        .sheet(isPresented: $showAddSheet) {
            DNSRecordFormSheet(zone: viewModel.zone) { newRecord in
                viewModel.insertOrUpdateRecordLocally(newRecord)
            }
        }
        .sheet(item: $recordToEdit) { record in
            DNSRecordFormSheet(zone: viewModel.zone, existingRecord: record) { updatedRecord in
                viewModel.insertOrUpdateRecordLocally(updatedRecord)
            }
        }
        .confirmationDialog(
            "Delete Record",
            isPresented: $showDeleteConfirmation,
            presenting: recordToDelete
        ) { record in
            Button("Delete \(record.name)", role: .destructive) {
                Task {
                    await viewModel.deleteRecord(id: record.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { record in
            Text("Permanently delete \(record.type) record for \(record.name)? Routing will cease immediately.")
        }
    }

    // MARK: - Search and Filter Section

    private var searchAndFilterSection: some View {
        VStack(spacing: GentleSpacing.sm) {
            GentleSearchBar(
                text: $viewModel.searchText,
                placeholder: "Search records by name, IP, or content"
            )

            // Horizontal scrolling type filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: GentleSpacing.xs) {
                    ForEach(DNSRecordTypeFilter.allCases) { filter in
                        let isSelected = viewModel.selectedFilter == filter
                        Button {
                            withAnimation(GentleAnimation.spring) {
                                viewModel.selectedFilter = filter
                            }
                            GentleHaptics.selection()
                        } label: {
                            Text(filter.rawValue)
                                .font(isSelected ? GentleTypography.subheadlineBold : GentleTypography.subheadline)
                                .padding(.horizontal, GentleSpacing.sm)
                                .padding(.vertical, 7)
                                .foregroundStyle(isSelected ? GentleColor.accent : GentleColor.textSecondary)
                                .background(
                                    RoundedRectangle(cornerRadius: GentleCornerRadius.md, style: .continuous)
                                        .fill(isSelected ? GentleColor.cardSurface : GentleColor.cardSurfaceSecondary)
                                        .shadow(color: isSelected ? Color.black.opacity(0.04) : Color.clear, radius: 4, x: 0, y: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Loaded Records Content

    private var loadedRecordsContent: some View {
        VStack(alignment: .leading, spacing: GentleSpacing.md) {
            if viewModel.filteredRecords.isEmpty {
                GentleEmptyStateView(
                    iconName: "magnifyingglass",
                    title: "No Matching Records",
                    message: "No DNS records match your filter or search criteria."
                )
                .padding(.top, GentleSpacing.lg)
            } else {
                // Header Count
                HStack {
                    Text("\(viewModel.filteredRecords.count) Records")
                        .font(GentleTypography.caption)
                        .foregroundStyle(GentleColor.textSecondary)

                    Spacer()
                }
                .padding(.horizontal, GentleSpacing.xs)

                // Records Cards
                LazyVStack(spacing: GentleSpacing.sm) {
                    ForEach(viewModel.filteredRecords) { record in
                        let isUpdating = viewModel.updatingRecordIds.contains(record.id)
                        DNSRecordRow(
                            record: record,
                            isUpdating: isUpdating,
                            onToggleProxy: {
                                Task {
                                    await viewModel.toggleProxy(for: record)
                                }
                            },
                            onEdit: {
                                recordToEdit = record
                            },
                            onDelete: {
                                recordToDelete = record
                                showDeleteConfirmation = true
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Loading Skeleton View

    private var loadingSkeletonView: some View {
        LazyVStack(spacing: GentleSpacing.sm) {
            ForEach(0 ..< 4, id: \.self) { _ in
                VStack(alignment: .leading, spacing: GentleSpacing.xs) {
                    HStack {
                        RoundedRectangle(cornerRadius: GentleCornerRadius.xs, style: .continuous)
                            .fill(GentleColor.cardSurfaceSecondary)
                            .frame(width: 44, height: 20)

                        RoundedRectangle(cornerRadius: GentleCornerRadius.xs, style: .continuous)
                            .fill(GentleColor.cardSurfaceSecondary)
                            .frame(width: 160, height: 18)

                        Spacer()
                    }

                    RoundedRectangle(cornerRadius: GentleCornerRadius.sm, style: .continuous)
                        .fill(GentleColor.cardSurfaceSecondary.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)

                    HStack {
                        RoundedRectangle(cornerRadius: GentleCornerRadius.micro, style: .continuous)
                            .fill(GentleColor.cardSurfaceSecondary.opacity(0.5))
                            .frame(width: 70, height: 12)

                        Spacer()

                        RoundedRectangle(cornerRadius: GentleCornerRadius.xs, style: .continuous)
                            .fill(GentleColor.cardSurfaceSecondary.opacity(0.5))
                            .frame(width: 26, height: 26)
                    }
                }
                .gentleCardStyle(cornerRadius: GentleCornerRadius.card, padding: GentleSpacing.md)
                .gentleShimmer()
            }
        }
    }
}
