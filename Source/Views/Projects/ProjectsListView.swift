//
//  ProjectsListView.swift
//  TaskLuid
//

import SwiftUI

struct ProjectsListView: View {
    @ObservedObject var viewModel: ProjectsViewModel
    @State private var showCreate = false
    @State private var searchText = ""
    @State private var selectedFilter = "All"
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
                            if let errorMessage = viewModel.errorMessage {
                                InlineErrorView(message: errorMessage)
                            }
                            SearchBarView(placeholder: "Search projects", text: $searchText)
                            filterChips
                            ForEach(viewModel.projects) { project in
                                NavigationLink {
                                    ProjectDetailView(project: project)
                            } label: {
                                ProjectRowView(project: project)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .screenPadding()
                }
                .background(LLColors.background.color(for: colorScheme))
            }
        }
        .sheet(isPresented: $showCreate) {
            ProjectCreateView { name, description in
                let project = await viewModel.createProject(name: name, description: description)
                if project == nil {
                    return viewModel.errorMessage ?? "Failed to create project."
                }
                return nil
            }
        }
        .task {
            await viewModel.loadProjects()
        }
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            SectionHeaderView("Projects", subtitle: "Track everything in one place.")
            Spacer()
            Button {
                showCreate = true
            } label: {
                Image(systemName: "plus")
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LLSpacing.sm) {
                ForEach(["All", "Favorites", "Active", "Archived"], id: \.self) { label in
                    let isSelected = selectedFilter == label
                    LLButton(label, style: isSelected ? .primary : .outline, size: .sm) {
                        selectedFilter = label
                    }
                }
            }
        }
    }
}
