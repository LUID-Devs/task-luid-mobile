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
    @State private var viewMode = "List"
    @State private var statusFilter: String? = nil
    @State private var priorityFilter: TaskPriority? = nil
    @State private var sortBy = "Priority"
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
                        filterBar
                        filterChips
                        viewToggleRow
                        if !selectedTaskIds.isEmpty {
                            selectionBar
                            if let selectionError {
                                InlineErrorView(message: selectionError)
                            }
                        }
                        if filteredTasks.isEmpty {
                            LLEmptyState(
                                icon: "checklist",
                                title: "No matching tasks",
                                message: "Try adjusting your filters."
                            )
                        } else {
                        if viewMode == "Table" {
                            tableView
                        } else {
                                ForEach(filteredTasks) { task in
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

    private var filterBar: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Search & Filter")
                    .h4()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LLSpacing.sm) {
                        Menu {
                            Button("Sort by Priority") { sortBy = "Priority" }
                            Button("Sort by Status") { sortBy = "Status" }
                            Button("Sort by Due Date") { sortBy = "Due Date" }
                        } label: {
                            filterChipLabel("Sort", value: sortBy)
                        }

                        Menu {
                            Button("All status") { statusFilter = nil }
                            ForEach(statusOptions, id: \.self) { status in
                                Button(status) { statusFilter = status }
                            }
                        } label: {
                            filterChipLabel("Status", value: statusFilter)
                        }

                        Menu {
                            Button("All priority") { priorityFilter = nil }
                            ForEach(TaskPriority.allCases) { priority in
                                Button(priority.rawValue) { priorityFilter = priority }
                            }
                        } label: {
                            filterChipLabel("Priority", value: priorityFilter?.rawValue)
                        }

                        if hasActiveFilters {
                            LLButton("Clear", style: .ghost, size: .sm) {
                                searchText = ""
                                statusFilter = nil
                                priorityFilter = nil
                                sortBy = "Priority"
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
                viewMode = "List"
            } label: {
                Image(systemName: "list.bullet")
                    .foregroundColor(viewMode == "List" ? LLColors.primaryForeground.color(for: colorScheme) : LLColors.foreground.color(for: colorScheme))
                    .padding(8)
                    .background(viewMode == "List" ? LLColors.primary.color(for: colorScheme) : LLColors.muted.color(for: colorScheme))
                    .cornerRadius(10)
            }
            Button {
                viewMode = "Table"
            } label: {
                Image(systemName: "tablecells")
                    .foregroundColor(viewMode == "Table" ? LLColors.primaryForeground.color(for: colorScheme) : LLColors.foreground.color(for: colorScheme))
                    .padding(8)
                    .background(viewMode == "Table" ? LLColors.primary.color(for: colorScheme) : LLColors.muted.color(for: colorScheme))
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
        !searchText.isEmpty || statusFilter != nil || priorityFilter != nil || sortBy != "Priority"
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
        LLBackgroundView()
    }

    private func isOverdue(_ task: TaskItem) -> Bool {
        guard task.status != .completed,
              let dueDate = parseDate(task.dueDate) else { return false }
        return dueDate < Date()
    }

    private var filteredTasks: [TaskItem] {
        let userId = authViewModel.user?.userId
        let base = viewModel.tasks.filter { task in
            switch selectedFilter {
            case "Assigned":
                return task.assignedUserId == userId
            case "Created":
                return task.authorUserId == userId
            case "Overdue":
                return isOverdue(task)
            case "Completed":
                return task.status == .completed
            default:
                return true
            }
        }

        let searched = base.filter { task in
            guard !searchText.isEmpty else { return true }
            let query = searchText.lowercased()
            let matchesTitle = task.title.lowercased().contains(query)
            let matchesDescription = task.description?.lowercased().contains(query) ?? false
            let matchesTags = task.tags?.lowercased().contains(query) ?? false
            return matchesTitle || matchesDescription || matchesTags
        }

        let statusFiltered = searched.filter { task in
            guard let statusFilter else { return true }
            return task.status?.rawValue == statusFilter
        }

        let priorityFiltered = statusFiltered.filter { task in
            guard let priorityFilter else { return true }
            return task.priority == priorityFilter
        }

        return priorityFiltered.sorted { lhs, rhs in
            switch sortBy {
            case "Status":
                return statusOrder(lhs.status) < statusOrder(rhs.status)
            case "Due Date":
                return (parseDate(lhs.dueDate) ?? .distantFuture) < (parseDate(rhs.dueDate) ?? .distantFuture)
            default:
                return priorityOrder(lhs.priority) < priorityOrder(rhs.priority)
            }
        }
    }

    private func priorityOrder(_ priority: TaskPriority?) -> Int {
        switch priority {
        case .urgent: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        case .backlog: return 4
        default: return 5
        }
    }

    private func statusOrder(_ status: TaskStatus?) -> Int {
        switch status {
        case .toDo: return 0
        case .workInProgress: return 1
        case .underReview: return 2
        case .completed: return 3
        default: return 4
        }
    }

    @ViewBuilder
    private var tableView: some View {
        let selectWidth: CGFloat = 24
        let priorityWidth: CGFloat = 70
        let statusWidth: CGFloat = 90
        let dueWidth: CGFloat = 70

        LLCard(style: .standard) {
            VStack(spacing: LLSpacing.sm) {
                HStack {
                    Button {
                        toggleSelectAll()
                    } label: {
                        Image(systemName: allVisibleSelected ? "checkmark.square.fill" : "square")
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .frame(width: selectWidth, alignment: .leading)

                    Text("Task")
                        .captionText()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(1)
                    Text("Priority")
                        .captionText()
                        .frame(width: priorityWidth, alignment: .leading)
                    Text("Status")
                        .captionText()
                        .frame(width: statusWidth, alignment: .leading)
                    Text("Due")
                        .captionText()
                        .frame(width: dueWidth, alignment: .leading)
                }
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                Divider()
                    .background(LLColors.muted.color(for: colorScheme))

                ForEach(filteredTasks) { task in
                    NavigationLink {
                        TaskDetailView(task: task, onTaskUpdated: { updated in
                            viewModel.upsertTask(updated)
                        })
                    } label: {
                        HStack {
                            Button {
                                toggleSelection(for: task.id)
                            } label: {
                                Image(systemName: selectedTaskIds.contains(task.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedTaskIds.contains(task.id) ? LLColors.foreground.color(for: colorScheme) : LLColors.mutedForeground.color(for: colorScheme))
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .frame(width: selectWidth, alignment: .leading)

                            VStack(alignment: .leading, spacing: LLSpacing.xs) {
                                Text(task.title)
                                    .bodyText()
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                if let description = task.description, !description.isEmpty {
                                    Text(description)
                                        .bodySmall()
                                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .layoutPriority(1)
                            Text(task.priority?.rawValue ?? "—")
                                .bodySmall()
                                .frame(width: priorityWidth, alignment: .leading)
                            Text(task.status?.rawValue ?? "—")
                                .bodySmall()
                                .frame(width: statusWidth, alignment: .leading)
                            Text(formattedDueDate(task) ?? "—")
                                .bodySmall()
                                .frame(width: dueWidth, alignment: .leading)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Divider()
                        .background(LLColors.muted.color(for: colorScheme))
                }
            }
        }
    }

    private func formattedDueDate(_ task: TaskItem) -> String? {
        guard let date = parseDate(task.dueDate) else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func toggleSelection(for taskId: Int) {
        if selectedTaskIds.contains(taskId) {
            selectedTaskIds.remove(taskId)
        } else {
            selectedTaskIds.insert(taskId)
        }
    }

    private var allVisibleSelected: Bool {
        !filteredTasks.isEmpty && filteredTasks.allSatisfy { selectedTaskIds.contains($0.id) }
    }

    private func toggleSelectAll() {
        if allVisibleSelected {
            filteredTasks.forEach { selectedTaskIds.remove($0.id) }
        } else {
            filteredTasks.forEach { selectedTaskIds.insert($0.id) }
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
        do {
            _ = try await TaskService.shared.bulkDelete(taskIds: ids)
            viewModel.tasks.removeAll { selectedTaskIds.contains($0.id) }
            selectedTaskIds.removeAll()
        } catch {
            selectionError = error.localizedDescription
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

        let ids = Array(selectedTaskIds)
        do {
            _ = try await TaskService.shared.bulkUpdateStatus(taskIds: ids, status: status)
            for taskId in ids {
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
            }
        } catch {
            selectionError = error.localizedDescription
        }
    }

    private func updateSelectedAssignee(_ userId: Int?) async {
        guard !selectedTaskIds.isEmpty else { return }
        isBulkUpdating = true
        selectionError = nil
        defer { isBulkUpdating = false }

        let assignee = usersViewModel.users.first { $0.userId == userId }

        let ids = Array(selectedTaskIds)
        do {
            _ = try await TaskService.shared.bulkAssign(taskIds: ids, assignedUserId: userId)
            for taskId in ids {
                guard let index = viewModel.tasks.firstIndex(where: { $0.id == taskId }) else { continue }
                let task = viewModel.tasks[index]
                viewModel.tasks[index] = TaskItem(
                    id: task.id,
                    title: task.title,
                    description: task.description,
                    descriptionImageUrl: task.descriptionImageUrl,
                    status: task.status,
                    priority: task.priority,
                    taskType: task.taskType,
                    tags: task.tags,
                    startDate: task.startDate,
                    dueDate: task.dueDate,
                    points: task.points,
                    projectId: task.projectId,
                    authorUserId: task.authorUserId,
                    assignedUserId: userId,
                    author: task.author,
                    assignee: assignee,
                    comments: task.comments,
                    attachments: task.attachments
                )
            }
        } catch {
            selectionError = error.localizedDescription
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
