//
//  TasksListView.swift
//  TaskLuid
//

import SwiftUI

struct TasksListView: View {
    @StateObject private var viewModel = TasksViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var selectedFilter = "Assigned"

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    LLLoadingView("Loading tasks...")
                } else if viewModel.tasks.isEmpty {
                    LLEmptyState(
                        icon: "checklist",
                        title: "No tasks",
                        message: "Tasks assigned to you will show up here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: LLSpacing.md) {
                            SectionHeaderView("My tasks", subtitle: "Focus on what needs attention.")
                            SearchBarView(placeholder: "Search tasks", text: $searchText)
                            filterChips
                            ForEach(viewModel.tasks) { task in
                                NavigationLink {
                                    TaskDetailView(task: task)
                                } label: {
                                    TaskRowView(task: task)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .screenPadding()
                    }
                    .background(LLColors.background.color(for: colorScheme))
                }
            }
            .navigationTitle("My Tasks")
            .task {
                if let userId = authViewModel.user?.userId {
                    await viewModel.loadTasksByUser(userId: userId)
                }
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LLSpacing.sm) {
                ForEach(["Assigned", "Created", "Overdue", "Completed"], id: \.self) { label in
                    let isSelected = selectedFilter == label
                    LLButton(label, style: isSelected ? .primary : .outline, size: .sm) {
                        selectedFilter = label
                    }
                }
            }
        }
    }
}
