//
//  ProjectsListView.swift
//  TaskLuid
//

import SwiftUI

struct ProjectsListView: View {
    @ObservedObject var viewModel: ProjectsViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showCreate = false
    @State private var searchText = ""
    @State private var selectedTab = "All"
    @State private var viewMode = "Grid"
    @State private var sortBy = "Name"
    @State private var statusFilter: String? = nil
    @State private var didInitialLoad = false
    @State private var isInitialLoading = false
    @State private var favoriteInFlight: Set<Int> = []
    @State private var favoriteError: String? = nil
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if viewModel.isLoading {
                LLLoadingView("Loading projects...")
            } else if viewModel.projects.isEmpty {
                VStack(spacing: LLSpacing.md) {
                    if let errorMessage = viewModel.errorMessage {
                        InlineErrorView(message: errorMessage)
                    }
                    LLEmptyState(
                        icon: "folder",
                        title: "No projects",
                        message: "Create your first project to get started.",
                        actionTitle: "New Project"
                    ) {
                        showCreate = true
                    }
                }
            } else {
                ScrollView {
                    VStack(spacing: LLSpacing.md) {
                        headerRow
                        if let favoriteError {
                            InlineErrorView(message: favoriteError)
                        }
                        if let errorMessage = viewModel.errorMessage {
                            InlineErrorView(message: errorMessage)
                        }
                        tabsRow
                        filterBar
                        viewToggleRow
                        if filteredProjects.isEmpty {
                            LLEmptyState(
                                icon: "folder",
                                title: "No matching projects",
                                message: "Try adjusting your filters."
                            )
                        } else {
                            if viewMode == "Grid" {
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: LLSpacing.md) {
                                    ForEach(filteredProjects) { project in
                                        projectGridCard(project)
                                    }
                                }
                            } else {
                                ForEach(filteredProjects) { project in
                                    projectRowWithFavorite(project)
                                }
                            }
                        }
                    }
                }
                .screenPadding()
            }
        }
        .background(LLColors.background.color(for: colorScheme))
        .sheet(isPresented: $showCreate) {
            ProjectCreateView { name, description in
                let project = await viewModel.createProject(name: name, description: description)
                if project == nil {
                    return viewModel.errorMessage ?? "Failed to create project."
                }
                return nil
            }
        }
        .onAppear {
            startInitialLoad()
        }
        .onChange(of: authViewModel.user?.userId) { _ in
            startInitialLoad()
        }
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            SectionHeaderView(headerTitle, subtitle: headerSubtitle)
            Spacer()
            if selectedTab == "All" {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))
                }
            }
        }
    }

    private var tabsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LLSpacing.sm) {
                ForEach(["All", "Favorites", "Archived"], id: \.self) { label in
                    let isSelected = selectedTab == label
                    LLButton(label, style: isSelected ? .primary : .outline, size: .sm) {
                        selectedTab = label
                    }
                }
            }
        }
    }

    private var filterBar: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Search & Filter")
                    .h4()
                SearchBarView(placeholder: "Search projects", text: $searchText)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LLSpacing.sm) {
                        Menu {
                            Button("Sort by Name") { sortBy = "Name" }
                            Button("Sort by Date") { sortBy = "Date" }
                            Button("Sort by Progress") { sortBy = "Progress" }
                        } label: {
                            filterChipLabel("Sort", value: sortBy)
                        }

                        Menu {
                            Button("All status") { statusFilter = nil }
                            Button("Active") { statusFilter = "Active" }
                            Button("Completed") { statusFilter = "Completed" }
                            Button("Overdue") { statusFilter = "Overdue" }
                        } label: {
                            filterChipLabel("Status", value: statusFilter)
                        }

                        if hasActiveFilters {
                            LLButton("Clear", style: .ghost, size: .sm) {
                                searchText = ""
                                sortBy = "Name"
                                statusFilter = nil
                            }
                        }
                    }
                }
            }
        }
    }

    private var viewToggleRow: some View {
        HStack(spacing: LLSpacing.sm) {
            Text("View")
                .captionText()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            Button {
                viewMode = "Grid"
            } label: {
                Image(systemName: "square.grid.2x2")
                    .foregroundColor(viewMode == "Grid" ? LLColors.primaryForeground.color(for: colorScheme) : LLColors.foreground.color(for: colorScheme))
                    .padding(8)
                    .background(viewMode == "Grid" ? LLColors.primary.color(for: colorScheme) : LLColors.muted.color(for: colorScheme))
                    .cornerRadius(10)
            }
            Button {
                viewMode = "List"
            } label: {
                Image(systemName: "list.bullet")
                    .foregroundColor(viewMode == "List" ? LLColors.primaryForeground.color(for: colorScheme) : LLColors.foreground.color(for: colorScheme))
                    .padding(8)
                    .background(viewMode == "List" ? LLColors.primary.color(for: colorScheme) : LLColors.muted.color(for: colorScheme))
                    .cornerRadius(10)
            }
            Spacer()
        }
    }

    private func filterChipLabel(_ title: String, value: String?) -> some View {
        HStack(spacing: LLSpacing.xs) {
            Text(title)
                .bodySmall()
            if let value, !value.isEmpty {
                LLBadge(value, variant: .outline, size: .sm)
            } else {
                Text("All")
                    .bodySmall()
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
            Image(systemName: "chevron.down")
                .font(.caption2)
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
        .padding(.horizontal, LLSpacing.sm)
        .padding(.vertical, LLSpacing.xs)
        .background(LLColors.muted.color(for: colorScheme))
        .cornerRadius(12)
    }

    private var hasActiveFilters: Bool {
        !searchText.isEmpty || statusFilter != nil || sortBy != "Name"
    }

    private var headerTitle: String {
        switch selectedTab {
        case "Favorites": return "Favorite Projects"
        case "Archived": return "Archived Projects"
        default: return "Projects"
        }
    }

    private var headerSubtitle: String {
        let count = filteredProjects.count
        return "\(count) project\(count == 1 ? "" : "s")"
    }

    private var filteredProjects: [Project] {
        let base = viewModel.projects.filter { project in
            if selectedTab == "Favorites" {
                return project.isFavorited == true
            }
            if selectedTab == "Archived" {
                return project.archived == true
            }
            return true
        }

        let searched = base.filter { project in
            guard !searchText.isEmpty else { return true }
            let query = searchText.lowercased()
            let matchesName = project.name.lowercased().contains(query)
            let matchesDescription = project.description?.lowercased().contains(query) ?? false
            return matchesName || matchesDescription
        }

        let statusFiltered = searched.filter { project in
            guard let statusFilter else { return true }
            let status = project.statistics?.status ?? ""
            return status.lowercased() == statusFilter.lowercased()
        }

        return statusFiltered.sorted { lhs, rhs in
            switch sortBy {
            case "Date":
                return parseDate(lhs.startDate) ?? .distantPast > parseDate(rhs.startDate) ?? .distantPast
            case "Progress":
                return (lhs.statistics?.progress ?? 0) > (rhs.statistics?.progress ?? 0)
            default:
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        }
    }

    private func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: value) {
            return date
        }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: value)
    }

    private func projectGridCard(_ project: Project) -> some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink {
                ProjectDetailView(project: project)
            } label: {
                LLCard(style: .standard) {
                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        HStack(alignment: .top) {
                            Text(project.name)
                                .h4()
                                .lineLimit(2)
                            Spacer()
                        }
                        if let description = project.description, !description.isEmpty {
                            Text(description)
                                .bodySmall()
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                .lineLimit(2)
                        }
                        HStack(spacing: LLSpacing.xs) {
                            if let status = project.statistics?.status {
                                LLBadge(status, variant: .outline, size: .sm)
                            }
                            if let progress = project.statistics?.progress {
                                LLBadge("\(Int(progress * 100))%", variant: .outline, size: .sm)
                            }
                        }
                        if let count = project.taskCount {
                            Text("\(count) tasks")
                                .captionText()
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: 150, alignment: .topLeading)
                }
            }
            .buttonStyle(PlainButtonStyle())

            favoriteButton(project)
                .padding(8)
        }
    }

    private func projectRowWithFavorite(_ project: Project) -> some View {
        HStack(spacing: LLSpacing.sm) {
            NavigationLink {
                ProjectDetailView(project: project)
            } label: {
                ProjectRowView(project: project)
            }
            .buttonStyle(PlainButtonStyle())
            favoriteButton(project)
        }
    }

    private func favoriteButton(_ project: Project) -> some View {
        let isFavorited = project.isFavorited == true
        return Button {
            Task { await toggleFavorite(project) }
        } label: {
            Image(systemName: isFavorited ? "star.fill" : "star")
                .foregroundColor(isFavorited ? LLColors.warning.color(for: colorScheme) : LLColors.mutedForeground.color(for: colorScheme))
                .padding(6)
                .background(LLColors.muted.color(for: colorScheme))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(favoriteInFlight.contains(project.id))
    }

    private func toggleFavorite(_ project: Project) async {
        guard !favoriteInFlight.contains(project.id) else { return }
        guard let userId = authViewModel.user?.userId else {
            favoriteError = "User ID is required."
            return
        }
        favoriteInFlight.insert(project.id)
        favoriteError = nil
        defer { favoriteInFlight.remove(project.id) }

        do {
            if project.isFavorited == true {
                try await ProjectService.shared.unfavoriteProject(projectId: project.id, userId: userId)
            } else {
                try await ProjectService.shared.favoriteProject(projectId: project.id, userId: userId)
            }
            await viewModel.loadProjects(userId: authViewModel.user?.userId, force: true)
        } catch {
            favoriteError = error.localizedDescription
        }
    }

    private func startInitialLoad() {
        guard !didInitialLoad, !isInitialLoading else { return }
        guard authViewModel.user?.userId != nil else { return }
        isInitialLoading = true
        Task {
            await viewModel.loadProjects(userId: authViewModel.user?.userId)
            didInitialLoad = true
            isInitialLoading = false
        }
    }
}
