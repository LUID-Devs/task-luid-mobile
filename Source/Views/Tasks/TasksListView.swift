//
//  TasksListView.swift
//  TaskLuid
//

import SwiftUI

struct TasksListView: View {
    @ObservedObject var viewModel: TasksViewModel
    @ObservedObject var usersViewModel: UsersViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var selectedFilter = "Assigned"
    @State private var selectedTaskIds: Set<Int> = []
    @State private var showDeleteConfirm = false
    @State private var isDeletingSelected = false
    @State private var selectionError: String? = nil
    @State private var isBulkUpdating = false
    @State private var showStatusPicker = false
    @State private var showAssignPicker = false
    @State private var showMovePicker = false
    @State private var projects: [Project] = []
    @State private var lastLoadedProjectsForUserId: Int? = nil
    @State private var isInitialLoading = false
    @State private var didInitialLoad = false
    private let tasksDidChange = Notification.Name("tasksDidChange")

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
                        summaryStrip
                        if let debug = viewModel.debugResponse {
                            LLBadge(debug, variant: .outline, size: .sm)
                        }
                        SearchBarView(placeholder: "Search tasks", text: $searchText)
                        filterChips
                        if !selectedTaskIds.isEmpty {
                            selectionBar
                            if let selectionError {
                                InlineErrorView(message: selectionError)
                            }
                        }
                        ForEach(viewModel.tasks) { task in
                            NavigationLink {
                                TaskDetailView(task: task, onTaskUpdated: { updated in
                                    viewModel.upsertTask(updated)
                                })
                            } label: {
                                TaskRowView(
                                    task: task,
                                    showsSelection: true,
                                    isSelected: selectedTaskIds.contains(task.id),
                                    onSelectToggle: {
                                        toggleSelection(for: task.id)
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .screenPadding()
                }
                .background(tasksBackground)
            }
        }
        .alert("Delete selected tasks?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task { await deleteSelectedTasks() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(selectedTaskIds.count) task(s).")
        }
        .confirmationDialog("Set status", isPresented: $showStatusPicker) {
            ForEach(statusOptions, id: \.self) { status in
                Button(status) {
                    Task { await updateSelectedStatus(status) }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Assign to", isPresented: $showAssignPicker) {
            Button("Unassigned") {
                Task { await updateSelectedAssignee(nil) }
            }
            ForEach(usersViewModel.users) { user in
                Button(user.username) {
                    Task { await updateSelectedAssignee(user.userId) }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Move to project", isPresented: $showMovePicker) {
            ForEach(projects) { project in
                Button(project.name) {
                    Task { await moveSelectedTasks(projectId: project.id) }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            if let userId = authViewModel.user?.userId {
                startInitialLoad(userId: userId)
            }
        }
        .onChange(of: authViewModel.user?.userId) { newValue in
            if let userId = newValue {
                startInitialLoad(userId: userId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: tasksDidChange)) { _ in
            guard let userId = authViewModel.user?.userId else { return }
            Task { await viewModel.loadTasksByUser(userId: userId, force: true) }
        }
    }

    private var headerRow: some View {
        VStack(alignment: .leading, spacing: LLSpacing.xs) {
            Text("My Tasks")
                .h2()
        }
    }

    private var summaryStrip: some View {
        let userId = authViewModel.user?.userId
        let assignedCount = viewModel.tasks.filter { $0.assignedUserId == userId }.count
        let createdCount = viewModel.tasks.filter { $0.authorUserId == userId }.count
        let overdueCount = viewModel.tasks.filter { isOverdue($0) }.count
        let completedCount = viewModel.tasks.filter { $0.status == .completed }.count

        let stats = [
            ("Assigned", assignedCount),
            ("Created", createdCount),
            ("Overdue", overdueCount),
            ("Completed", completedCount)
        ]

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LLSpacing.sm) {
                ForEach(stats, id: \.0) { label, value in
                    LLCard(style: .standard, padding: .sm) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(label)
                                .captionText()
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                            Text("\(value)")
                                .h4()
                        }
                    }
                    .frame(width: 110)
                }
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LLSpacing.sm) {
                ForEach(["Assigned", "Created", "Overdue", "Completed"], id: \.self) { label in
                    let isSelected = selectedFilter == label
                    LLButton(label, style: isSelected ? .secondary : .outline, size: .sm) {
                        selectedFilter = label
                    }
                }
            }
        }
    }

    private var selectionBar: some View {
        LLCard(style: .standard) {
            VStack(spacing: LLSpacing.sm) {
                HStack {
                    Text("\(selectedTaskIds.count) selected")
                        .bodySmall()
                    Spacer()
                    LLButton("Clear", style: .ghost, size: .sm) {
                        selectedTaskIds.removeAll()
                    }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LLSpacing.sm) {
                        LLButton("Status", style: .outline, size: .sm, isLoading: isBulkUpdating) {
                            showStatusPicker = true
                        }
                        LLButton("Assign", style: .outline, size: .sm, isLoading: isBulkUpdating) {
                            showAssignPicker = true
                        }
                        LLButton("Move", style: .outline, size: .sm, isLoading: isBulkUpdating) {
                            showMovePicker = true
                        }
                        LLButton("Delete", style: .destructive, size: .sm, isLoading: isDeletingSelected) {
                            showDeleteConfirm = true
                        }
                    }
                }
            }
        }
    }

    private var tasksBackground: some View {
        LinearGradient(
            colors: [
                LLColors.background.color(for: colorScheme),
                LLColors.muted.color(for: colorScheme)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func isOverdue(_ task: TaskItem) -> Bool {
        guard task.status != .completed,
              let dueDate = parseDate(task.dueDate) else { return false }
        return dueDate < Date()
    }

    private func toggleSelection(for taskId: Int) {
        if selectedTaskIds.contains(taskId) {
            selectedTaskIds.remove(taskId)
        } else {
            selectedTaskIds.insert(taskId)
        }
    }

    private func startInitialLoad(userId: Int) {
        guard !didInitialLoad, !isInitialLoading else { return }
        isInitialLoading = true
        Task {
            await viewModel.loadTasksByUser(userId: userId)
            await usersViewModel.loadUsers()
            await loadProjects(userId: userId)
            didInitialLoad = true
            isInitialLoading = false
        }
    }

    private func deleteSelectedTasks() async {
        guard !selectedTaskIds.isEmpty else { return }
        isDeletingSelected = true
        selectionError = nil
        defer { isDeletingSelected = false }

        let ids = Array(selectedTaskIds)
        for taskId in ids {
            do {
                _ = try await TaskService.shared.deleteTask(taskId: taskId)
                viewModel.tasks.removeAll { $0.id == taskId }
                selectedTaskIds.remove(taskId)
            } catch {
                selectionError = error.localizedDescription
                break
            }
        }
    }

    private var statusOptions: [String] {
        let defaults = ["To Do", "Work In Progress", "Under Review", "Completed"]
        let custom = viewModel.tasks.compactMap { $0.status?.rawValue }
        return Array(Set(defaults + custom)).sorted()
    }

    private func updateSelectedStatus(_ status: String) async {
        guard !selectedTaskIds.isEmpty else { return }
        isBulkUpdating = true
        selectionError = nil
        defer { isBulkUpdating = false }

        for taskId in selectedTaskIds {
            do {
                _ = try await TaskService.shared.updateTaskStatus(taskId: taskId, statusName: status)
                if let index = viewModel.tasks.firstIndex(where: { $0.id == taskId }) {
                    let task = viewModel.tasks[index]
                    viewModel.tasks[index] = TaskItem(
                        id: task.id,
                        title: task.title,
                        description: task.description,
                        descriptionImageUrl: task.descriptionImageUrl,
                        status: TaskStatus(rawValue: status) ?? task.status,
                        priority: task.priority,
                        taskType: task.taskType,
                        tags: task.tags,
                        startDate: task.startDate,
                        dueDate: task.dueDate,
                        points: task.points,
                        projectId: task.projectId,
                        authorUserId: task.authorUserId,
                        assignedUserId: task.assignedUserId,
                        author: task.author,
                        assignee: task.assignee,
                        comments: task.comments,
                        attachments: task.attachments
                    )
                }
            } catch {
                selectionError = error.localizedDescription
                break
            }
        }
    }

    private func updateSelectedAssignee(_ userId: Int?) async {
        guard !selectedTaskIds.isEmpty else { return }
        isBulkUpdating = true
        selectionError = nil
        defer { isBulkUpdating = false }

        let assignee = usersViewModel.users.first { $0.userId == userId }

        for taskId in selectedTaskIds {
            guard let index = viewModel.tasks.firstIndex(where: { $0.id == taskId }) else { continue }
            let task = viewModel.tasks[index]
            do {
                let updated = try await TaskService.shared.updateTask(
                    taskId: task.id,
                    title: task.title,
                    description: task.description,
                    status: task.status?.rawValue,
                    priority: task.priority,
                    tags: task.tags,
                    startDate: task.startDate,
                    dueDate: task.dueDate,
                    points: task.points,
                    assignedUserId: userId
                )
                viewModel.tasks[index] = TaskItem(
                    id: updated.id,
                    title: updated.title,
                    description: updated.description,
                    descriptionImageUrl: updated.descriptionImageUrl,
                    status: updated.status ?? task.status,
                    priority: updated.priority ?? task.priority,
                    taskType: updated.taskType ?? task.taskType,
                    tags: updated.tags ?? task.tags,
                    startDate: updated.startDate ?? task.startDate,
                    dueDate: updated.dueDate ?? task.dueDate,
                    points: updated.points ?? task.points,
                    projectId: updated.projectId,
                    authorUserId: updated.authorUserId ?? task.authorUserId,
                    assignedUserId: userId,
                    author: updated.author ?? task.author,
                    assignee: assignee,
                    comments: task.comments,
                    attachments: task.attachments
                )
            } catch {
                selectionError = error.localizedDescription
                break
            }
        }
    }

    private func moveSelectedTasks(projectId: Int) async {
        guard !selectedTaskIds.isEmpty else { return }
        isBulkUpdating = true
        selectionError = nil
        defer { isBulkUpdating = false }

        for taskId in selectedTaskIds {
            guard let index = viewModel.tasks.firstIndex(where: { $0.id == taskId }) else { continue }
            let task = viewModel.tasks[index]
            do {
                let updated = try await TaskService.shared.updateTask(
                    taskId: task.id,
                    title: task.title,
                    description: task.description,
                    status: task.status?.rawValue,
                    priority: task.priority,
                    tags: task.tags,
                    startDate: task.startDate,
                    dueDate: task.dueDate,
                    points: task.points,
                    assignedUserId: task.assignedUserId,
                    projectId: projectId
                )
                viewModel.tasks[index] = TaskItem(
                    id: updated.id,
                    title: updated.title,
                    description: updated.description,
                    descriptionImageUrl: updated.descriptionImageUrl,
                    status: updated.status ?? task.status,
                    priority: updated.priority ?? task.priority,
                    taskType: updated.taskType ?? task.taskType,
                    tags: updated.tags ?? task.tags,
                    startDate: updated.startDate ?? task.startDate,
                    dueDate: updated.dueDate ?? task.dueDate,
                    points: updated.points ?? task.points,
                    projectId: projectId,
                    authorUserId: updated.authorUserId ?? task.authorUserId,
                    assignedUserId: updated.assignedUserId ?? task.assignedUserId,
                    author: updated.author ?? task.author,
                    assignee: updated.assignee ?? task.assignee,
                    comments: task.comments,
                    attachments: task.attachments
                )
            } catch {
                selectionError = error.localizedDescription
                break
            }
        }
    }

    private func loadProjects(userId: Int) async {
        if lastLoadedProjectsForUserId == userId, !projects.isEmpty {
            return
        }
        do {
            projects = try await ProjectService.shared.getProjects(userId: userId)
            lastLoadedProjectsForUserId = userId
        } catch {
            projects = []
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
}
