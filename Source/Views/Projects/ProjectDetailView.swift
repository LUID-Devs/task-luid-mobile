//
//  ProjectDetailView.swift
//  TaskLuid
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct ProjectDetailView: View {
    let project: Project

    @StateObject private var tasksViewModel = TasksViewModel()
    @StateObject private var usersViewModel = UsersViewModel()
    @State private var showCreateTask = false
    @State private var statuses: [ProjectStatus] = []
    @State private var isLoadingStatuses = false
    @State private var selectedView = "List"
    @State private var draggingTaskId: Int? = nil
    @State private var dropTargetStatus: String? = nil
    @State private var statusError: String? = nil
    @State private var statusActionError: String? = nil
    @State private var isColumnsLocked = true
    @State private var statusSheetMode: StatusSheetMode? = nil
    @State private var statusName = ""
    @State private var isSavingStatus = false
    @State private var statusToDelete: ProjectStatus? = nil
    @State private var showStatusManager = false
    @State private var taskToDelete: TaskItem? = nil
    @State private var navigationTask: TaskItem? = nil
    @State private var navigationTaskEditMode = false
    @State private var isNavigatingToTask = false
    @State private var isDuplicatingTask = false
    @State private var searchQuery = ""
    @State private var selectedStatusFilter: String? = nil
    @State private var selectedPriorityFilter: TaskPriority? = nil
    @State private var selectedAssigneeId: Int? = nil
    @Environment(\.colorScheme) private var colorScheme

    private let workflowChain = ["To Do", "Work In Progress", "Under Review", "Completed"]
    private let wipLimits: [String: Int] = [
        "To Do": 20,
        "Work In Progress": 5,
        "Under Review": 8,
        "Completed": .max
    ]

    private enum StatusSheetMode: Identifiable {
        case add
        case edit(ProjectStatus)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let status): return "edit-\(status.id)"
            }
        }
    }

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
                        filterBar
                        statusColumns
                        viewToggle
                        actionBar
                        if let navigationTask {
                            NavigationLink("", destination: TaskDetailView(task: navigationTask, startEditing: navigationTaskEditMode, onTaskUpdated: { updated in
                                tasksViewModel.upsertTask(updated)
                            }), isActive: $isNavigatingToTask)
                            .hidden()
                        }
                        if selectedView == "List" {
                            ForEach(filteredTasks) { task in
                                NavigationLink {
                                    TaskDetailView(task: task, onTaskUpdated: { updated in
                                        tasksViewModel.upsertTask(updated)
                                    })
                                } label: {
                                    TaskRowView(task: task)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        } else if selectedView == "Board" {
                            boardView
                        } else if selectedView == "Timeline" {
                            timelineView
                        } else if selectedView == "Table" {
                            tableView
                        } else {
                            LLEmptyState(
                                icon: "square.grid.2x2",
                                title: "\(selectedView) view",
                                message: "This view is coming soon."
                            )
                        }
                    }
                    .screenPadding()
                }
                .appBackground()
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
            TaskCreateView(projectId: project.id) { request in
                let task = await tasksViewModel.createTask(
                    title: request.title,
                    description: request.description,
                    projectId: project.id,
                    priority: request.priority,
                    status: request.status,
                    tags: request.tags,
                    startDate: request.startDate,
                    dueDate: request.dueDate,
                    points: Int(request.points),
                    taskType: request.taskType,
                    assignedUserId: request.assigneeId,
                    authorUserId: request.authorUserId
                )
                if task == nil {
                    return (nil, tasksViewModel.errorMessage ?? "Failed to create task.")
                }
                NotificationCenter.default.post(name: Notification.Name("tasksDidChange"), object: nil)
                return (task, nil)
            }
        }
        .sheet(item: $statusSheetMode) { mode in
            statusEditorSheet(mode: mode)
        }
        .sheet(isPresented: $showStatusManager) {
            statusManagerSheet
        }
        .alert("Delete Task", isPresented: Binding(get: {
            taskToDelete != nil
        }, set: { value in
            if !value { taskToDelete = nil }
        })) {
            Button("Delete", role: .destructive) {
                Task { await deleteTask() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this task?")
        }
        .alert("Delete Status", isPresented: Binding(get: {
            statusToDelete != nil
        }, set: { value in
            if !value { statusToDelete = nil }
        })) {
            Button("Delete", role: .destructive) {
                Task { await deleteStatus() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Tasks in this status will be moved to \"To Do\".")
        }
        .task {
            await tasksViewModel.loadTasks(projectId: project.id, force: true)
            await loadStatuses()
            await usersViewModel.loadUsers()
        }
    }

    private var projectHeader: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                HStack {
                    Text(project.name)
                        .h3()
                    Spacer()
                    if project.isFavorited == true {
                        Image(systemName: "star.fill")
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))
                    }
                }
                if let description = project.description, !description.isEmpty {
                    Text(description)
                        .bodySmall()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
                HStack(spacing: LLSpacing.sm) {
                    LLBadge("Tasks: \(tasksViewModel.tasks.count)", variant: .outline, size: .sm)
                    if let stats = project.statistics {
                        LLBadge("\(Int(stats.progress * 100))% complete", variant: .outline, size: .sm)
                    }
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
                            let count = filteredTasks.filter { $0.status?.rawValue == status.name }.count
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

    private var viewToggle: some View {
        Picker("View", selection: $selectedView) {
            Text("List").tag("List")
            Text("Board").tag("Board")
            Text("Timeline").tag("Timeline")
            Text("Table").tag("Table")
        }
        .pickerStyle(SegmentedPickerStyle())
    }

    private var actionBar: some View {
        HStack(spacing: LLSpacing.sm) {
            LLButton("New task", style: .primary, size: .sm, fullWidth: true) {
                showCreateTask = true
            }
            LLButton("Statuses", style: .outline, size: .sm, fullWidth: true) {
                showStatusManager = true
            }
            LLButton("Members", style: .outline, size: .sm, fullWidth: true) {}
        }
    }

    private var boardView: some View {
        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            if let statusError {
                InlineErrorView(message: statusError)
            }
            if let statusActionError {
                InlineErrorView(message: statusActionError)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: LLSpacing.md) {
                    ForEach(statuses.isEmpty ? fallbackStatuses : statuses) { status in
                        let columnTasks = filteredTasks.filter { $0.status?.rawValue == status.name }
                        VStack(alignment: .leading, spacing: LLSpacing.sm) {
                            columnHeader(status: status, count: columnTasks.count)

                            ForEach(columnTasks) { task in
                                NavigationLink {
                                    TaskDetailView(task: task, onTaskUpdated: { updated in
                                        tasksViewModel.upsertTask(updated)
                                    })
                                } label: {
                                    boardTaskCard(task)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .onDrag {
                                    draggingTaskId = task.id
                                    return NSItemProvider(object: String(task.id) as NSString)
                                }
                            }

                            if columnTasks.isEmpty {
                                Text("Drop tasks here")
                                    .bodySmall()
                                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, LLSpacing.md)
                            }
                        }
                        .padding(LLSpacing.sm)
                        .frame(width: 240)
                        .background(dropTargetStatus == status.name ? LLColors.muted.color(for: colorScheme) : LLColors.card.color(for: colorScheme))
                        .cornerRadius(LLSpacing.radiusLG)
                        .onDrop(of: [UTType.text], isTargeted: Binding(get: {
                            dropTargetStatus == status.name
                        }, set: { isTargeted in
                            dropTargetStatus = isTargeted ? status.name : nil
                        })) { providers in
                            handleDrop(providers: providers, statusName: status.name)
                        }
                    }
                }
                .padding(.vertical, LLSpacing.sm)
            }
        }
    }

    private var filterBar: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Search & Filter")
                    .h4()
                SearchBarView(placeholder: "Search tasks", text: $searchQuery)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LLSpacing.sm) {
                        Menu {
                            Button("All statuses") { selectedStatusFilter = nil }
                            ForEach(availableStatusNames, id: \.self) { status in
                                Button(status) { selectedStatusFilter = status }
                            }
                        } label: {
                            filterChipLabel("Status", value: selectedStatusFilter)
                        }

                        Menu {
                            Button("All priorities") { selectedPriorityFilter = nil }
                            ForEach(TaskPriority.allCases, id: \.self) { priority in
                                Button(priority.rawValue) { selectedPriorityFilter = priority }
                            }
                        } label: {
                            filterChipLabel("Priority", value: selectedPriorityFilter?.rawValue)
                        }

                        Menu {
                            Button("All assignees") { selectedAssigneeId = nil }
                            Button("Unassigned") { selectedAssigneeId = 0 }
                            ForEach(usersViewModel.users) { user in
                                Button(user.username) { selectedAssigneeId = user.userId }
                            }
                        } label: {
                            let assigneeName = assigneeFilterLabel()
                            filterChipLabel("Assignee", value: assigneeName)
                        }

                        if hasActiveFilters {
                            LLButton("Clear", style: .ghost, size: .sm) {
                                searchQuery = ""
                                selectedStatusFilter = nil
                                selectedPriorityFilter = nil
                                selectedAssigneeId = nil
                            }
                        }
                    }
                }
            }
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
        !searchQuery.isEmpty || selectedStatusFilter != nil || selectedPriorityFilter != nil || selectedAssigneeId != nil
    }

    private func assigneeFilterLabel() -> String? {
        guard let selectedAssigneeId else { return nil }
        if selectedAssigneeId == 0 { return "Unassigned" }
        return usersViewModel.users.first(where: { $0.userId == selectedAssigneeId })?.username ?? "Assignee"
    }

    private var availableStatusNames: [String] {
        let list = (statuses.isEmpty ? fallbackStatuses : statuses).map(\.name)
        return Array(Set(list)).sorted()
    }

    private var filteredTasks: [TaskItem] {
        tasksViewModel.tasks.filter { task in
            if !searchQuery.isEmpty {
                let query = searchQuery.lowercased()
                let matchesTitle = task.title.lowercased().contains(query)
                let matchesDescription = task.description?.lowercased().contains(query) ?? false
                let matchesTags = task.tags?.lowercased().contains(query) ?? false
                if !(matchesTitle || matchesDescription || matchesTags) {
                    return false
                }
            }

            if let selectedStatusFilter, task.status?.rawValue != selectedStatusFilter {
                return false
            }

            if let selectedPriorityFilter, task.priority != selectedPriorityFilter {
                return false
            }

            if let selectedAssigneeId {
                if selectedAssigneeId == 0 {
                    if task.assignedUserId != nil {
                        return false
                    }
                } else if task.assignedUserId != selectedAssigneeId {
                    return false
                }
            }
            return true
        }
    }

    @ViewBuilder
    private var tableView: some View {
        let priorityWidth: CGFloat = 70
        let statusWidth: CGFloat = 90
        let dueWidth: CGFloat = 70

        LLCard(style: .standard) {
            VStack(spacing: LLSpacing.sm) {
                HStack {
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
                    Button {
                        openTask(task, edit: false)
                    } label: {
                        HStack {
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

    @ViewBuilder
    private var timelineView: some View {
        let grouped = Dictionary(grouping: filteredTasks.compactMap { task -> (String, TaskItem)? in
            guard let due = task.dueDate, let date = parseDate(due) else {
                return ("Unscheduled", task)
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            return (formatter.string(from: date), task)
        }, by: { $0.0 })

        if grouped.isEmpty {
            LLEmptyState(
                icon: "calendar",
                title: "No upcoming tasks",
                message: "Tasks with due dates will show here."
            )
        } else {
            VStack(spacing: LLSpacing.md) {
            ForEach(grouped.keys.sorted(), id: \.self) { key in
                let tasks = grouped[key]?.map { $0.1 } ?? []
                LLCard(style: .standard) {
                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        Text(key)
                            .h4()
                        ForEach(tasks) { task in
                            HStack(alignment: .top, spacing: LLSpacing.sm) {
                                VStack(alignment: .leading, spacing: LLSpacing.xs) {
                                    Text(task.title)
                                        .bodyText()
                                    if let due = formattedDueDate(task) {
                                        Text("Due \(due)")
                                            .captionText()
                                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                    }
                                }
                                Spacer()
                                if let status = task.status {
                                    LLBadge(status.rawValue, variant: status == .completed ? .success : .outline, size: .sm)
                                }
                            }
                            Divider()
                                .background(LLColors.muted.color(for: colorScheme))
                        }
                    }
                }
            }
        }
        }
    }

    private func boardTaskCard(_ task: TaskItem) -> some View {
        LLCard(style: .standard, padding: .sm) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                if let previewURL = attachmentPreviewURL(for: task) {
                    AsyncImage(url: previewURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Rectangle()
                                .fill(LLColors.muted.color(for: colorScheme))
                        case .empty:
                            Rectangle()
                                .fill(LLColors.muted.color(for: colorScheme))
                                .overlay(ProgressView())
                        @unknown default:
                            Rectangle()
                                .fill(LLColors.muted.color(for: colorScheme))
                        }
                    }
                    .frame(height: 110)
                    .clipped()
                    .cornerRadius(LLSpacing.radiusMD)
                }

                HStack(alignment: .top, spacing: LLSpacing.sm) {
                    Text(task.title)
                        .bodyText()
                    Spacer()
                    taskMenu(task)
                }

                if let dueStatus = dueDateStatus(for: task) {
                    HStack(spacing: LLSpacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(dueStatus)
                            .bodySmall()
                    }
                    .foregroundColor(LLColors.warning.color(for: colorScheme))
                }

                HStack(spacing: LLSpacing.xs) {
                    if let priority = task.priority {
                        LLBadge(priority.rawValue, variant: .outline, size: .sm)
                    }
                    if let type = task.taskType?.rawValue {
                        LLBadge(type, variant: .outline, size: .sm)
                    }
                    let tags = Array(taskTags(task).prefix(2))
                    ForEach(tags, id: \.self) { tag in
                        LLBadge(tag, variant: .outline, size: .sm)
                    }
                    if taskTags(task).count > 2 {
                        Text("+\(taskTags(task).count - 2)")
                            .bodySmall()
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }

                HStack {
                    assigneeSummary(task)
                    Spacer()
                    HStack(spacing: LLSpacing.sm) {
                        if let dueDate = formattedDueDate(task) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                Text(dueDate)
                            }
                            .font(LLTypography.bodySmall())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                        let commentCount = task.comments?.count ?? 0
                        if commentCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "message")
                                Text("\(commentCount)")
                            }
                            .font(LLTypography.bodySmall())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                    }
                }
            }
        }
    }

    private func columnHeader(status: ProjectStatus, count: Int) -> some View {
        HStack(spacing: LLSpacing.xs) {
            Text(status.name)
                .h4()
            Text("\(count)")
                .bodySmall()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            Spacer()
            Menu {
                Button(isColumnsLocked ? "Unlock Columns" : "Lock Columns") {
                    isColumnsLocked.toggle()
                }

                Button("Move Left") {
                    Task { await moveColumn(status: status, direction: -1) }
                }
                .disabled(!canMoveLeft(status))

                Button("Move Right") {
                    Task { await moveColumn(status: status, direction: 1) }
                }
                .disabled(!canMoveRight(status))

                Divider()

                Button("Add Status") {
                    statusName = ""
                    statusSheetMode = .add
                }

                Button("Edit Status") {
                    statusName = status.name
                    statusSheetMode = .edit(status)
                }
                .disabled(statuses.isEmpty)

                Button("Delete Status", role: .destructive) {
                    statusToDelete = status
                }
                .disabled(status.isDefault || statuses.isEmpty)
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.bottom, LLSpacing.xs)
    }

    @ViewBuilder
    private func taskMenu(_ task: TaskItem) -> some View {
        let shareURL = taskShareURL(task)
        Menu {
            Button {
                openTask(task, edit: false)
            } label: {
                Label("View", systemImage: "eye")
            }

            Button {
                openTask(task, edit: true)
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button {
                Task { await duplicateTask(task) }
            } label: {
                Label(isDuplicatingTask ? "Duplicating..." : "Duplicate", systemImage: "doc.on.doc")
            }
            .disabled(isDuplicatingTask)

            Button {
                if let shareURL {
                    UIPasteboard.general.string = shareURL.absoluteString
                }
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .disabled(shareURL == nil)

            Button(role: .destructive) {
                taskToDelete = task
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                .frame(width: 24, height: 24)
        }
    }

    private func statusEditorSheet(mode: StatusSheetMode) -> some View {
        VStack(spacing: LLSpacing.lg) {
            Text(modeTitle(mode))
                .h3()

            LLTextField(title: "Status name", placeholder: "Status name", text: $statusName)

            if let statusActionError {
                InlineErrorView(message: statusActionError)
            }

            HStack(spacing: LLSpacing.sm) {
                LLButton("Cancel", style: .outline, size: .sm, fullWidth: true) {
                    statusSheetMode = nil
                }
                LLButton(modePrimaryAction(mode), style: .primary, size: .sm, isLoading: isSavingStatus, fullWidth: true) {
                    Task { await saveStatus(mode) }
                }
            }
        }
        .screenPadding()
    }

    private var statusManagerSheet: some View {
        NavigationStack {
            VStack(spacing: LLSpacing.md) {
                if let statusActionError {
                    InlineErrorView(message: statusActionError)
                }
                if statuses.isEmpty {
                    LLEmptyState(
                        icon: "rectangle.stack",
                        title: "No statuses",
                        message: "Add a status to start organizing tasks."
                    )
                } else {
                    List {
                        ForEach(statuses) { status in
                            HStack(spacing: LLSpacing.sm) {
                                Text(status.name)
                                    .bodyText()
                                Spacer()
                                LLBadge(status.isDefault ? "Default" : status.name, variant: .outline, size: .sm)
                            }
                            .contentShape(Rectangle())
                            .contextMenu {
                                Button("Edit") {
                                    statusName = status.name
                                    statusSheetMode = .edit(status)
                                }
                                if !status.isDefault {
                                    Button("Delete", role: .destructive) {
                                        statusToDelete = status
                                    }
                                }
                            }
                        }
                        .onMove { indices, newOffset in
                            Task { await reorderStatuses(from: indices, to: newOffset) }
                        }
                    }
                    .listStyle(.plain)
                }

                LLButton("Add Status", style: .primary, size: .sm, fullWidth: true) {
                    statusName = ""
                    statusSheetMode = .add
                }
            }
            .screenPadding()
            .navigationTitle("Statuses")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        showStatusManager = false
                    }
                }
            }
        }
    }

    private func modeTitle(_ mode: StatusSheetMode) -> String {
        switch mode {
        case .add: return "Add Status"
        case .edit: return "Edit Status"
        }
    }

    private func modePrimaryAction(_ mode: StatusSheetMode) -> String {
        switch mode {
        case .add: return "Create"
        case .edit: return "Save"
        }
    }

    private func openTask(_ task: TaskItem, edit: Bool) {
        navigationTaskEditMode = edit
        navigationTask = task
        isNavigatingToTask = true
    }

    private func taskTags(_ task: TaskItem) -> [String] {
        (task.tags ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    @ViewBuilder
    private func assigneeSummary(_ task: TaskItem) -> some View {
        let name = task.assignee?.username ?? task.author?.username ?? "Unassigned"
        let initial = name.prefix(1).uppercased()
        HStack(spacing: LLSpacing.xs) {
            Circle()
                .fill(LLColors.muted.color(for: colorScheme))
                .frame(width: 22, height: 22)
                .overlay(
                    Text(initial)
                        .font(LLTypography.bodySmall())
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))
                )
            Text(name)
                .bodySmall()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
    }

    private func formattedDueDate(_ task: TaskItem) -> String? {
        guard let date = parseDate(task.dueDate) else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func dueDateStatus(for task: TaskItem) -> String? {
        guard let dueDate = parseDate(task.dueDate) else { return nil }
        if task.status == .completed { return nil }
        let now = Date()
        if dueDate < now {
            return "Overdue"
        }
        if let days = Calendar.current.dateComponents([.day], from: now, to: dueDate).day,
           days <= 2 {
            return "Due soon"
        }
        return nil
    }

    private func attachmentPreviewURL(for task: TaskItem) -> URL? {
        guard let attachment = task.attachments?.first else { return nil }
        let urlString = attachment.presignedUrl ?? attachment.fileURL
        guard urlString.lowercased().hasPrefix("http") else { return nil }
        let ext = (attachment.fileName ?? urlString).lowercased()
        if ext.hasSuffix(".png") || ext.hasSuffix(".jpg") || ext.hasSuffix(".jpeg") {
            return URL(string: urlString)
        }
        return nil
    }

    private func taskShareURL(_ task: TaskItem) -> URL? {
        URL(string: "\(AppConfig.webBaseURL)/dashboard/tasks/\(task.id)")
    }

    private func canMoveLeft(_ status: ProjectStatus) -> Bool {
        guard !isColumnsLocked,
              let index = statuses.firstIndex(where: { $0.id == status.id }) else {
            return false
        }
        return index > 0
    }

    private func canMoveRight(_ status: ProjectStatus) -> Bool {
        guard !isColumnsLocked,
              let index = statuses.firstIndex(where: { $0.id == status.id }) else {
            return false
        }
        return index < statuses.count - 1
    }

    private func moveColumn(status: ProjectStatus, direction: Int) async {
        guard let index = statuses.firstIndex(where: { $0.id == status.id }) else { return }
        let newIndex = index + direction
        guard newIndex >= 0, newIndex < statuses.count else { return }
        var reordered = statuses
        reordered.swapAt(index, newIndex)
        let statusIds = reordered.map(\.id)

        statusActionError = nil
        do {
            let updated = try await ProjectService.shared.reorderProjectStatuses(projectId: project.id, statusIds: statusIds)
            statuses = updated.sorted { $0.order < $1.order }
        } catch {
            statusActionError = error.localizedDescription
        }
    }

    private func reorderStatuses(from offsets: IndexSet, to destination: Int) async {
        var reordered = statuses
        reordered.move(fromOffsets: offsets, toOffset: destination)
        let statusIds = reordered.map(\.id)
        statusActionError = nil
        do {
            let updated = try await ProjectService.shared.reorderProjectStatuses(projectId: project.id, statusIds: statusIds)
            statuses = updated.sorted { $0.order < $1.order }
        } catch {
            statusActionError = error.localizedDescription
        }
    }

    private func saveStatus(_ mode: StatusSheetMode) async {
        let trimmed = statusName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusActionError = "Status name is required."
            return
        }

        isSavingStatus = true
        statusActionError = nil
        defer { isSavingStatus = false }

        do {
            switch mode {
            case .add:
                _ = try await ProjectService.shared.createProjectStatus(projectId: project.id, name: trimmed)
            case .edit(let status):
                _ = try await ProjectService.shared.updateProjectStatus(projectId: project.id, statusId: status.id, name: trimmed)
            }
            statusSheetMode = nil
            await loadStatuses()
            await tasksViewModel.loadTasks(projectId: project.id, force: true)
        } catch {
            statusActionError = error.localizedDescription
        }
    }

    private func deleteStatus() async {
        guard let status = statusToDelete else { return }
        statusActionError = nil
        defer { statusToDelete = nil }
        do {
            _ = try await ProjectService.shared.deleteProjectStatus(projectId: project.id, statusId: status.id, moveTasksTo: "To Do")
            await loadStatuses()
            await tasksViewModel.loadTasks(projectId: project.id, force: true)
        } catch {
            statusActionError = error.localizedDescription
        }
    }

    private func deleteTask() async {
        guard let task = taskToDelete else { return }
        statusActionError = nil
        defer { taskToDelete = nil }
        do {
            _ = try await TaskService.shared.deleteTask(taskId: task.id)
            tasksViewModel.tasks.removeAll { $0.id == task.id }
        } catch {
            statusActionError = error.localizedDescription
        }
    }

    private func duplicateTask(_ task: TaskItem) async {
        guard !isDuplicatingTask else { return }
        isDuplicatingTask = true
        statusActionError = nil
        defer { isDuplicatingTask = false }
        do {
            let duplicated = try await TaskService.shared.createTask(
                title: "\(task.title) (Copy)",
                description: task.description,
                projectId: task.projectId,
                priority: task.priority,
                status: task.status,
                tags: task.tags,
                startDate: task.startDate,
                dueDate: task.dueDate,
                points: task.points,
                taskType: task.taskType,
                authorUserId: task.authorUserId,
                assignedUserId: task.assignedUserId
            )
            tasksViewModel.tasks.insert(duplicated, at: 0)
        } catch {
            statusActionError = error.localizedDescription
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

    private func handleDrop(providers: [NSItemProvider], statusName: String) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            var value: String?
            if let data = item as? Data {
                value = String(data: data, encoding: .utf8)
            } else if let text = item as? String {
                value = text
            }
            guard let raw = value, let taskId = Int(raw) else { return }
            Task { await moveTask(taskId: taskId, to: statusName) }
        }
        return true
    }

    private func moveTask(taskId: Int, to statusName: String) async {
        guard let index = tasksViewModel.tasks.firstIndex(where: { $0.id == taskId }) else { return }
        let original = tasksViewModel.tasks[index]
        let fromStatus = original.status?.rawValue ?? "To Do"
        guard fromStatus != statusName else { return }

        if !isValidWorkflowTransition(from: fromStatus, to: statusName) {
            statusError = "Workflow violation: move tasks one step at a time."
            return
        }

        let currentCount = tasksViewModel.tasks.filter { ($0.status?.rawValue ?? "To Do") == statusName }.count
        let limit = wipLimits[statusName] ?? .max
        if limit != .max && currentCount >= limit {
            statusError = "WIP limit reached for \(statusName)."
            return
        }

        let nextStatus = TaskStatus(rawValue: statusName)
        tasksViewModel.tasks[index] = taskCopy(original, status: nextStatus ?? original.status)
        statusError = nil

        do {
            _ = try await TaskService.shared.updateTaskStatus(taskId: taskId, statusName: statusName)
        } catch {
            tasksViewModel.tasks[index] = original
            statusError = error.localizedDescription
        }
    }

    private func isValidWorkflowTransition(from: String, to: String) -> Bool {
        guard let fromIndex = workflowChain.firstIndex(of: from),
              let toIndex = workflowChain.firstIndex(of: to) else {
            return true
        }
        return toIndex <= fromIndex + 1
    }

    private func taskCopy(_ task: TaskItem, status: TaskStatus?) -> TaskItem {
        TaskItem(
            id: task.id,
            title: task.title,
            description: task.description,
            descriptionImageUrl: task.descriptionImageUrl,
            status: status,
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
