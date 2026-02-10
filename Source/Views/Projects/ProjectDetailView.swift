//
//  ProjectDetailView.swift
//  TaskLuid
//

import SwiftUI

struct ProjectDetailView: View {
    let project: Project

    @StateObject private var tasksViewModel = TasksViewModel()
    @State private var showCreateTask = false
    @State private var statuses: [ProjectStatus] = []
    @State private var isLoadingStatuses = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            if tasksViewModel.isLoading {
                LLLoadingView("Loading tasks...")
            } else if tasksViewModel.tasks.isEmpty {
                LLEmptyState(
                    icon: "checklist",
                    title: "No tasks",
                    message: "Add a task to this project.",
                    actionTitle: "New Task"
                ) {
                    showCreateTask = true
                }
            } else {
                ScrollView {
                    VStack(spacing: LLSpacing.md) {
                        projectHeader
                        statusColumns
                        actionBar
                        ForEach(tasksViewModel.tasks) { task in
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
        .navigationTitle(project.name)
        .toolbar {
            Button {
                showCreateTask = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showCreateTask) {
            TaskCreateView(projectId: project.id) { title, description, priority, status in
                Task {
                    _ = await tasksViewModel.createTask(
                        title: title,
                        description: description,
                        projectId: project.id,
                        priority: priority,
                        status: status
                    )
                }
            }
        }
        .task {
            await tasksViewModel.loadTasks(projectId: project.id)
            await loadStatuses()
        }
    }

    private var projectHeader: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text(project.name)
                    .h3()
                if let description = project.description, !description.isEmpty {
                    Text(description)
                        .bodySmall()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
                HStack(spacing: LLSpacing.sm) {
                    LLBadge("Tasks: \(tasksViewModel.tasks.count)", variant: .outline, size: .sm)
                    if project.archived == true {
                        LLBadge("Archived", variant: .warning, size: .sm)
                    }
                }
                membersRow
            }
        }
    }

    private var membersRow: some View {
        HStack(spacing: LLSpacing.sm) {
            if let members = project.teamMembers, !members.isEmpty {
                ForEach(members.prefix(3)) { member in
                    Circle()
                        .fill(LLColors.muted.color(for: colorScheme))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(member.username.prefix(1)).uppercased())
                                .font(LLTypography.bodySmall())
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                        )
                }
                if members.count > 3 {
                    Text("+\(members.count - 3)")
                        .bodySmall()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
            } else {
                Text("No members yet")
                    .bodySmall()
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
        }
    }

    private var statusColumns: some View {
        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            Text("Status")
                .h4()
            if isLoadingStatuses {
                LLLoadingView("Loading statuses...")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LLSpacing.sm) {
                        ForEach(statuses.isEmpty ? fallbackStatuses : statuses) { status in
                            let count = tasksViewModel.tasks.filter { $0.status?.rawValue == status.name }.count
                            LLCard(style: .standard, padding: .sm) {
                                VStack(alignment: .leading, spacing: LLSpacing.xs) {
                                    Text(status.name)
                                        .bodySmall()
                                    Text("\(count) tasks")
                                        .h4()
                                }
                            }
                            .frame(width: 140)
                        }
                    }
                }
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: LLSpacing.sm) {
            LLButton("New task", style: .primary, size: .sm, fullWidth: true) {
                showCreateTask = true
            }
            LLButton("Statuses", style: .outline, size: .sm, fullWidth: true) {}
            LLButton("Members", style: .outline, size: .sm, fullWidth: true) {}
        }
    }

    private var fallbackStatuses: [ProjectStatus] {
        [
            ProjectStatus(id: 0, name: "To Do", color: nil, order: 0, isDefault: true, projectId: project.id, createdAt: "", updatedAt: ""),
            ProjectStatus(id: 1, name: "Work In Progress", color: nil, order: 1, isDefault: true, projectId: project.id, createdAt: "", updatedAt: ""),
            ProjectStatus(id: 2, name: "Under Review", color: nil, order: 2, isDefault: true, projectId: project.id, createdAt: "", updatedAt: ""),
            ProjectStatus(id: 3, name: "Completed", color: nil, order: 3, isDefault: true, projectId: project.id, createdAt: "", updatedAt: "")
        ]
    }

    private func loadStatuses() async {
        isLoadingStatuses = true
        defer { isLoadingStatuses = false }

        do {
            statuses = try await ProjectService.shared.getProjectStatuses(projectId: project.id)
                .sorted { $0.order < $1.order }
        } catch {
            statuses = []
        }
    }
}
