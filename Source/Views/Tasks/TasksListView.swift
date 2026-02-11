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
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                LLLoadingView("Loading tasks...")
            } else if viewModel.tasks.isEmpty {
                VStack(spacing: LLSpacing.sm) {
                    if let debug = viewModel.debugResponse {
                        LLBadge(debug, variant: .outline, size: .sm)
                    }
                    LLEmptyState(
                        icon: "checklist",
                        title: "No tasks",
                        message: "Tasks assigned to you will show up here."
                    )
                }
            } else {
                ScrollView {
                    VStack(spacing: LLSpacing.md) {
                        headerRow
                        if let debug = viewModel.debugResponse {
                            LLBadge(debug, variant: .outline, size: .sm)
                        }
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
        .onAppear {
            if hasLoaded {
                return
            }
            if let userId = authViewModel.user?.userId {
                hasLoaded = true
                Task { await viewModel.loadTasksByUser(userId: userId) }
            }
        }
        .onChange(of: authViewModel.user?.userId) { newValue in
            guard let userId = newValue, !hasLoaded else { return }
            hasLoaded = true
            Task { await viewModel.loadTasksByUser(userId: userId) }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            SectionHeaderView("My tasks", subtitle: "Focus on what needs attention.")
            Spacer()
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
