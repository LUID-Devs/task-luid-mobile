//
//  PriorityView.swift
//  TaskLuid
//

import SwiftUI

struct PriorityView: View {
    @StateObject private var viewModel = PriorityViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedPriority = TaskPriority.urgent

    var body: some View {
        ScrollView {
            VStack(spacing: LLSpacing.md) {
                SectionHeaderView("Priority Tasks", subtitle: "Sort tasks by urgency.")
                priorityPicker

                if viewModel.isLoading {
                    LLLoadingView("Loading tasks...")
                } else if let errorMessage = viewModel.errorMessage {
                    InlineErrorView(message: errorMessage)
                } else if filteredTasks.isEmpty {
                    LLEmptyState(
                        icon: "flag",
                        title: "No \(selectedPriority.rawValue.lowercased()) tasks",
                        message: "Tasks will appear once assigned."
                    )
                } else {
                    ForEach(filteredTasks) { task in
                        TaskRowView(task: task)
                    }
                }
            }
            .screenPadding()
        }
        .background(LLColors.background.color(for: colorScheme))
        .task(id: authViewModel.user?.userId) {
            if let userId = authViewModel.user?.userId {
                await viewModel.loadTasks(userId: userId)
            }
        }
    }

    private var priorityPicker: some View {
        Picker("Priority", selection: $selectedPriority) {
            Text("Urgent").tag(TaskPriority.urgent)
            Text("High").tag(TaskPriority.high)
            Text("Medium").tag(TaskPriority.medium)
            Text("Low").tag(TaskPriority.low)
            Text("Backlog").tag(TaskPriority.backlog)
        }
        .pickerStyle(SegmentedPickerStyle())
    }

    private var filteredTasks: [TaskItem] {
        viewModel.tasks.filter { task in
            task.priority == selectedPriority
        }
    }
}
