import SwiftUI

// MARK: - PagesDetailDeepLinkWrapper

// Apple HIG Compliant Pages Deep Link Context Resolver

struct PagesDetailDeepLinkWrapper: View {
    let projectId: String
    let onDismiss: () -> Void

    @State private var loadedProject: PagesProject?
    @State private var accountId: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let project = loadedProject, !accountId.isEmpty {
                PagesProjectDetailView(accountId: accountId, project: project)
            } else if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading Pages Project…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                NativeErrorStateView(errorMessage: errorMessage ?? String(localized: "Unable to load project")) {
                    Task { await loadProject() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    onDismiss()
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.accentColor)
            }
        }
        .task {
            await loadProject()
        }
    }

    private func loadProject() async {
        guard !projectId.isEmpty, projectId != "placeholder-pages", projectId != "placeholder" else {
            onDismiss()
            return
        }

        isLoading = true
        errorMessage = nil

        // 1. Resolve Account ID
        if let accounts = try? await ZoneService.shared.getAccounts(), let firstAcc = accounts.first {
            accountId = firstAcc.id
        } else if let zones = try? await ZoneService.shared.getZones().0, let acc = zones.first?.account {
            accountId = acc.id
        }

        guard !accountId.isEmpty else {
            errorMessage = "No Active Cloudflare Account Found"
            isLoading = false
            return
        }

        // 2. Fetch Pages Projects list to match
        if let projects = try? await PagesService.shared.listPagesProjects(accountId: accountId),
           let matched = projects.first(where: { $0.id == projectId || $0.name == projectId }) {
            loadedProject = matched
            isLoading = false
        } else {
            // Fallback: Create PagesProject with ID/name directly
            loadedProject = PagesProject(id: projectId, name: projectId)
            isLoading = false
        }
    }
}
