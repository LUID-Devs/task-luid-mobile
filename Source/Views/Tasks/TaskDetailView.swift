//
//  TaskDetailView.swift
//  TaskLuid
//

import SwiftUI
import UniformTypeIdentifiers

struct TaskDetailView: View {
    let task: TaskItem

    @State private var taskState: TaskItem
    @State private var selectedStatus: TaskStatus?
    @State private var isUpdating = false
    @State private var errorMessage: String? = nil
    @State private var isEditing = false
    @State private var editTitle: String = ""
    @State private var editDescription: String = ""
    @State private var editStatus: String = ""
    @State private var editPriority: TaskPriority = .medium
    @State private var editTags: String = ""
    @State private var editStartDate: Date? = nil
    @State private var editDueDate: Date? = nil
    @State private var editPoints: String = ""
    @State private var editAssigneeId: Int? = nil
    @State private var availableStatuses: [String] = []
    @State private var isLoadingStatuses = false

    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var isLoadingComments = false
    @State private var isPostingComment = false
    @State private var commentsError: String? = nil

    @State private var attachments: [Attachment] = []
    @State private var isLoadingAttachments = false
    @State private var isUploadingAttachment = false
    @State private var attachmentsError: String? = nil
    @State private var showFileImporter = false

    @State private var availableAgents: [Agent] = []
    @State private var agentAssignments: [TaskAgentAssignment] = []
    @State private var isLoadingAgents = false
    @State private var agentError: String? = nil

    @StateObject private var usersViewModel = UsersViewModel()
    @Environment(\.colorScheme) private var colorScheme

    init(task: TaskItem) {
        self.task = task
        _taskState = State(initialValue: task)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: LLSpacing.md) {
                LLCard(style: .standard) {
                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        HStack {
                            Text(taskState.title)
                                .h3()
                            Spacer()
                            Button(isEditing ? "Cancel" : "Edit Task") {
                                if isEditing {
                                    applyTaskToForm(taskState)
                                }
                                isEditing.toggle()
                            }
                            .font(LLTypography.bodySmall())
                        }
                        if let description = taskState.description, !description.isEmpty {
                            Text(description)
                                .bodyText()
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                        HStack(spacing: LLSpacing.sm) {
                            if let priority = taskState.priority {
                                LLBadge(priority.rawValue, variant: .outline, size: .sm)
                            }
                            if let status = taskState.status {
                                LLBadge(status.rawValue, variant: status == .completed ? .success : .default, size: .sm)
                            }
                        }
                    }
                }

                if isEditing {
                    LLCard(style: .standard) {
                        VStack(alignment: .leading, spacing: LLSpacing.sm) {
                            Text("Edit details")
                                .h4()
                            LLTextField(title: "Title", placeholder: "Title", text: $editTitle)
                            LLTextField(title: "Description", placeholder: "Description", text: $editDescription)

                            Picker("Status", selection: $editStatus) {
                                ForEach(availableStatuses.isEmpty ? fallbackStatuses : availableStatuses, id: \.self) { status in
                                    Text(status).tag(status)
                                }
                            }
                            .pickerStyle(.menu)

                            Picker("Priority", selection: $editPriority) {
                                ForEach(TaskPriority.allCases) { priority in
                                    Text(priority.rawValue).tag(priority)
                                }
                            }
                            .pickerStyle(.menu)

                            LLTextField(title: "Tags", placeholder: "ui, backend", text: $editTags)
                            LLTextField(title: "Points", placeholder: "0", text: $editPoints)

                            DatePicker("Start date", selection: Binding(get: {
                                editStartDate ?? Date()
                            }, set: { editStartDate = $0 }), displayedComponents: .date)

                            DatePicker("Due date", selection: Binding(get: {
                                editDueDate ?? Date()
                            }, set: { editDueDate = $0 }), displayedComponents: .date)

                            Picker("Assignee", selection: $editAssigneeId) {
                                Text("Unassigned").tag(Int?.none)
                                ForEach(usersViewModel.users) { user in
                                    Text(user.username).tag(Int?.some(user.userId))
                                }
                            }
                            .pickerStyle(.menu)

                            if let errorMessage = errorMessage {
                                InlineErrorView(message: errorMessage)
                            }

                            LLButton("Save", style: .primary, isLoading: isUpdating, fullWidth: true) {
                                Task { await saveEdits() }
                            }
                        }
                    }
                }

                LLCard(style: .standard) {
                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        detailHeader("Priority & Status", icon: "flag")
                        detailRow(label: "Priority", value: taskState.priority?.rawValue ?? "-")
                        detailRow(label: "Status", value: taskState.status?.rawValue ?? "-")
                    }
                }

                LLCard(style: .standard) {
                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        detailHeader("Dates", icon: "calendar")
                        detailRow(label: "Due", value: taskState.dueDate ?? "-")
                        detailRow(label: "Start", value: taskState.startDate ?? "-")
                    }
                }

                LLCard(style: .standard) {
                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        detailHeader("People", icon: "person")
                        detailRow(label: "Assignee", value: taskState.assignee?.username ?? "Unassigned")
                        detailRow(label: "Author", value: taskState.author?.username ?? "-")
                    }
                }

                agentSection

                LLCard(style: .standard) {
                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        Text("Update Status")
                            .h4()

                        Picker("Status", selection: $selectedStatus) {
                            Text("None").tag(TaskStatus?.none)
                            ForEach(TaskStatus.allCases) { status in
                                Text(status.rawValue).tag(TaskStatus?.some(status))
                            }
                        }
                        .pickerStyle(.menu)

                        if let errorMessage = errorMessage {
                            InlineErrorView(message: errorMessage)
                        }

                        LLButton("Save", style: .primary, isLoading: isUpdating, fullWidth: true) {
                            Task { await updateStatus() }
                        }
                    }
                }

                commentsSection
                attachmentsSection
            }
            .screenPadding()
        }
        .navigationTitle("Task")
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.data, .image, .pdf, .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task { await uploadAttachment(fileURL: url) }
                }
            case .failure(let error):
                attachmentsError = error.localizedDescription
            }
        }
        .onAppear {
            selectedStatus = taskState.status
            applyTaskToForm(taskState)
            comments = taskState.comments ?? []
            attachments = taskState.attachments ?? []
            Task { await loadStatuses() }
            Task { await usersViewModel.loadUsers() }
            Task { await loadComments() }
            Task { await loadAttachments() }
            Task { await loadAgentsAndAssignments() }
        }
    }

    private func detailHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: LLSpacing.xs) {
            Image(systemName: icon)
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            Text(title)
                .h4()
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .bodySmall()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            Spacer()
            Text(value)
                .bodySmall()
        }
    }

    private func updateStatus() async {
        guard let selectedStatus else { return }
        isUpdating = true
        errorMessage = nil
        defer { isUpdating = false }

        do {
            taskState = try await TaskService.shared.updateTaskStatus(taskId: taskState.id, status: selectedStatus)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyTaskToForm(_ task: TaskItem) {
        editTitle = task.title
        editDescription = task.description ?? ""
        editStatus = task.status?.rawValue ?? "To Do"
        editPriority = task.priority ?? .medium
        editTags = task.tags ?? ""
        editPoints = task.points.map(String.init) ?? ""
        editAssigneeId = task.assignedUserId
        editStartDate = parseDate(task.startDate)
        editDueDate = parseDate(task.dueDate)
    }

    private func saveEdits() async {
        isUpdating = true
        errorMessage = nil
        defer { isUpdating = false }

        do {
            let updated = try await TaskService.shared.updateTask(
                taskId: taskState.id,
                title: editTitle,
                description: editDescription.isEmpty ? nil : editDescription,
                status: editStatus,
                priority: editPriority,
                tags: editTags.isEmpty ? nil : editTags,
                startDate: isoString(from: editStartDate),
                dueDate: isoString(from: editDueDate),
                points: Int(editPoints),
                assignedUserId: editAssigneeId
            )
            taskState = updated
            isEditing = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadStatuses() async {
        let projectId = taskState.projectId
        isLoadingStatuses = true
        defer { isLoadingStatuses = false }

        do {
            let statuses = try await ProjectService.shared.getProjectStatuses(projectId: projectId)
            availableStatuses = statuses.map { $0.name }
        } catch {
            availableStatuses = []
        }
    }

    private var fallbackStatuses: [String] {
        ["To Do", "Work In Progress", "Under Review", "Completed"]
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

    private func isoString(from date: Date?) -> String? {
        guard let date else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        return iso.string(from: date)
    }

    private var commentsSection: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Comments")
                    .h4()

                if isLoadingComments {
                    LLLoadingView("Loading comments...")
                } else if comments.isEmpty {
                    Text("No comments yet.")
                        .bodySmall()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                } else {
                    ForEach(comments) { comment in
                        VStack(alignment: .leading, spacing: LLSpacing.xs) {
                            HStack {
                                Text(comment.user.username)
                                    .bodySmall()
                                Spacer()
                                Button("Delete") {
                                    Task { await deleteComment(comment) }
                                }
                                .font(LLTypography.caption())
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                            }
                            Text(comment.text)
                                .bodyText()
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                        .padding(.vertical, LLSpacing.xs)
                    }
                }

                LLTextField(title: "Add comment", placeholder: "Write a comment", text: $newCommentText)

                if let commentsError = commentsError {
                    InlineErrorView(message: commentsError)
                }

                LLButton("Post Comment", style: .secondary, isLoading: isPostingComment, fullWidth: true) {
                    Task { await postComment() }
                }
            }
        }
    }

    private var attachmentsSection: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Attachments")
                    .h4()

                if isLoadingAttachments {
                    LLLoadingView("Loading attachments...")
                } else if attachments.isEmpty {
                    Text("No attachments.")
                        .bodySmall()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                } else {
                    ForEach(attachments) { attachment in
                        HStack {
                            Image(systemName: "paperclip")
                            VStack(alignment: .leading, spacing: 2) {
                                Text(attachment.fileName ?? "Attachment")
                                    .bodyText()
                                if let url = URL(string: attachment.presignedUrl ?? attachment.fileURL) {
                                    Link("Open", destination: url)
                                        .font(LLTypography.bodySmall())
                                }
                            }
                            Spacer()
                            Button("Remove") {
                                Task { await deleteAttachment(attachment) }
                            }
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))
                    }
                }

                if let attachmentsError = attachmentsError {
                    InlineErrorView(message: attachmentsError)
                }

                LLButton("Add Attachment", style: .secondary, isLoading: isUploadingAttachment, fullWidth: true) {
                    showFileImporter = true
                }
            }
        }
    }

    private var agentSection: some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                detailHeader("Agents", icon: "person.3")

                if isLoadingAgents {
                    LLLoadingView("Loading agents...")
                } else {
                    if agentAssignments.isEmpty {
                        Text("No agents assigned.")
                            .bodySmall()
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    } else {
                        ForEach(agentAssignments) { assignment in
                            let displayName = assignment.agent?.displayName ?? "Agent #\\(assignment.agentId)"
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(displayName)
                                        .bodyText()
                                    Text(assignment.status)
                                        .bodySmall()
                                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                }
                                Spacer()
                                Button("Unassign") {
                                    Task { await toggleAgentById(assignment.agentId) }
                                }
                                .font(LLTypography.caption())
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                            }
                        }
                    }

                    if !availableAgents.isEmpty {
                        Divider()
                        Text("Available agents")
                            .bodySmall()
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                        ForEach(availableAgents) { agent in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(agent.displayName)
                                        .bodyText()
                                    Text(agent.role)
                                        .bodySmall()
                                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                }
                                Spacer()
                                let isAssigned = isAgentAssigned(agent)
                                Button(isAssigned ? "Unassign" : "Assign") {
                                    Task { await toggleAgent(agent) }
                                }
                                .font(LLTypography.caption())
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                            }
                        }
                    }
                }

                if let agentError = agentError {
                    InlineErrorView(message: agentError)
                }
            }
        }
    }

    private func loadComments() async {
        isLoadingComments = true
        commentsError = nil
        defer { isLoadingComments = false }

        do {
            comments = try await CommentService.shared.getTaskComments(taskId: taskState.id)
        } catch {
            commentsError = error.localizedDescription
        }
    }

    private func postComment() async {
        let trimmed = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isPostingComment = true
        commentsError = nil
        defer { isPostingComment = false }

        do {
            let created = try await CommentService.shared.createComment(taskId: taskState.id, text: trimmed)
            comments.insert(created, at: 0)
            newCommentText = ""
        } catch {
            commentsError = error.localizedDescription
        }
    }

    private func deleteComment(_ comment: Comment) async {
        commentsError = nil
        do {
            _ = try await CommentService.shared.deleteComment(commentId: comment.id)
            comments.removeAll { $0.id == comment.id }
        } catch {
            commentsError = error.localizedDescription
        }
    }

    private func loadAttachments() async {
        isLoadingAttachments = true
        attachmentsError = nil
        defer { isLoadingAttachments = false }

        do {
            attachments = try await AttachmentService.shared.getTaskAttachments(taskId: taskState.id)
        } catch {
            attachmentsError = error.localizedDescription
        }
    }

    private func uploadAttachment(fileURL: URL) async {
        isUploadingAttachment = true
        attachmentsError = nil
        defer { isUploadingAttachment = false }

        do {
            let created = try await AttachmentService.shared.uploadAttachment(taskId: taskState.id, fileURL: fileURL)
            attachments.append(created)
        } catch {
            attachmentsError = error.localizedDescription
        }
    }

    private func deleteAttachment(_ attachment: Attachment) async {
        attachmentsError = nil
        do {
            _ = try await AttachmentService.shared.deleteAttachment(attachmentId: attachment.id)
            attachments.removeAll { $0.id == attachment.id }
        } catch {
            attachmentsError = error.localizedDescription
        }
    }

    private func loadAgentsAndAssignments() async {
        isLoadingAgents = true
        agentError = nil
        defer { isLoadingAgents = false }

        do {
            let orgId = KeychainManager.shared.getActiveOrganizationId().flatMap { Int($0) }
            if let orgId {
                availableAgents = try await MissionControlService.shared.getAgents(organizationId: orgId)
            } else {
                availableAgents = try await MissionControlService.shared.getAgents()
            }
            agentAssignments = try await MissionControlService.shared.getTaskAgentAssignments(taskId: taskState.id)
        } catch {
            agentError = error.localizedDescription
        }
    }

    private func isAgentAssigned(_ agent: Agent) -> Bool {
        agentAssignments.contains { $0.agentId == agent.id }
    }

    private func toggleAgent(_ agent: Agent) async {
        await toggleAgentById(agent.id)
    }

    private func toggleAgentById(_ agentId: Int) async {
        isLoadingAgents = true
        agentError = nil
        defer { isLoadingAgents = false }

        do {
            if agentAssignments.contains(where: { $0.agentId == agentId }) {
                _ = try await MissionControlService.shared.unassignTaskFromAgent(taskId: taskState.id, agentId: agentId)
            } else {
                _ = try await MissionControlService.shared.assignTaskToAgents(taskId: taskState.id, agentIds: [agentId])
            }
            agentAssignments = try await MissionControlService.shared.getTaskAgentAssignments(taskId: taskState.id)
        } catch {
            agentError = error.localizedDescription
        }
    }
}
