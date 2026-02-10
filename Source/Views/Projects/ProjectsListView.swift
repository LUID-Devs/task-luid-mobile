//
//  ProjectsListView.swift
//  TaskLuid
//

import SwiftUI

struct ProjectsListView: View {
    @StateObject private var viewModel = ProjectsViewModel()
    @State private var showCreate = false
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LLLoadingView("Loading projects...")
                } else if viewModel.projects.isEmpty {
                    LLEmptyState(
                        icon: "folder",
                        title: "No projects",
                        message: "Create your first project to get started.",
                        actionTitle: "New Project"
                    ) {
                        showCreate = true
                    }
                } else {
                    ScrollView {
                        VStack(spacing: LLSpacing.md) {
                            SectionHeaderView("Projects", subtitle: "Track everything in one place.")
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
            .navigationTitle("Projects")
            .toolbar {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showCreate) {
                ProjectCreateView { name, description in
                    Task {
                        _ = await viewModel.createProject(name: name, description: description)
                        showCreate = false
                    }
                }
            }
            .task {
                await viewModel.loadProjects()
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
