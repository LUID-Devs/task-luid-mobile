//
//  TaskDetailView.swift
//  TaskLuid
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct TaskDetailView: View {
    let task: TaskItem
    let startEditing: Bool
    let onTaskUpdated: ((TaskItem) -> Void)?

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
    @State private var showCommentImagePicker = false
    @State private var isUploadingCommentImage = false
    @State private var commentImageUrl: String? = nil
    @State private var commentPhotoItem: PhotosPickerItem? = nil

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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(task: TaskItem, startEditing: Bool = false, onTaskUpdated: ((TaskItem) -> Void)? = nil) {
        self.task = task
        self.startEditing = startEditing
        self.onTaskUpdated = onTaskUpdated
        _taskState = State(initialValue: task)
        _isEditing = State(initialValue: startEditing)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: LLSpacing.md) {
                VStack(spacing: LLSpacing.md) {
                    LLCard(style: .standard) {
                        VStack(alignment: .leading, spacing: LLSpacing.sm) {
                            HStack {
                                Text(taskState.title)
                                    .bodyText()
                                    .fontWeight(.semibold)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)
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

                    LLCard(style: .standard) {
                        VStack(alignment: .leading, spacing: LLSpacing.sm) {
                            detailHeader("Priority/Status", icon: "flag")
                            detailRow(label: "Priority", value: taskState.priority?.rawValue ?? "-")
                            detailRow(label: "Status", value: taskState.status?.rawValue ?? "-")
                        }
                    }
                }

                if isEditing {
                    LLCard(style: .standard) {
                        VStack(alignment: .leading, spacing: LLSpacing.md) {
                            Text("Edit Task")
                                .h4()

                            editFormContent

                            if let errorMessage = errorMessage {
                                InlineErrorView(message: errorMessage)
                            }

                            LLButton("Save Changes", style: .primary, isLoading: isUpdating, fullWidth: true) {
                                Task { await saveEdits() }
                            }
                        }
                    }
                }

                

                VStack(spacing: LLSpacing.md) {
                    LLCard(style: .standard) {
                        VStack(alignment: .leading, spacing: LLSpacing.sm) {
                            detailHeader("Dates", icon: "calendar")
                            detailRow(label: "Due", value: displayDate(taskState.dueDate))
                            detailRow(label: "Start", value: displayDate(taskState.startDate))
                        }
                    }

                    LLCard(style: .standard) {
                        VStack(alignment: .leading, spacing: LLSpacing.sm) {
                            detailHeader("People", icon: "person")
                            detailRow(label: "Assignee", value: taskState.assignee?.username ?? "Unassigned")
                            detailRow(label: "Author", value: taskState.author?.username ?? "-")
                        }
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
        .fileImporter(
            isPresented: $showCommentImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task { await uploadCommentImage(fileURL: url) }
                }
            case .failure(let error):
                commentsError = error.localizedDescription
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
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .layoutPriority(1)
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .bodySmall()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            Text(value)
                .bodySmall()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private func updateStatus() async {
        guard let selectedStatus else { return }
        isUpdating = true
        errorMessage = nil
        let previous = taskState
        taskState = TaskItem(
            id: previous.id,
            title: previous.title,
            description: previous.description,
            descriptionImageUrl: previous.descriptionImageUrl,
            status: selectedStatus,
            priority: previous.priority,
            taskType: previous.taskType,
            tags: previous.tags,
            startDate: previous.startDate,
            dueDate: previous.dueDate,
            points: previous.points,
            projectId: previous.projectId,
            authorUserId: previous.authorUserId,
            assignedUserId: previous.assignedUserId,
            author: previous.author,
            assignee: previous.assignee,
            comments: previous.comments,
            attachments: previous.attachments
        )
        defer { isUpdating = false }

        do {
            let updated = try await TaskService.shared.updateTaskStatus(taskId: taskState.id, status: selectedStatus)
            taskState = TaskItem(
                id: updated.id,
                title: updated.title,
                description: updated.description,
                descriptionImageUrl: updated.descriptionImageUrl,
                status: updated.status ?? selectedStatus,
                priority: updated.priority ?? taskState.priority,
                taskType: updated.taskType ?? taskState.taskType,
                tags: updated.tags ?? taskState.tags,
                startDate: updated.startDate ?? taskState.startDate,
                dueDate: updated.dueDate ?? taskState.dueDate,
                points: updated.points ?? taskState.points,
                projectId: updated.projectId,
                authorUserId: updated.authorUserId ?? taskState.authorUserId,
                assignedUserId: updated.assignedUserId ?? taskState.assignedUserId,
                author: updated.author ?? taskState.author,
                assignee: updated.assignee ?? taskState.assignee,
                comments: taskState.comments,
                attachments: taskState.attachments
            )
            onTaskUpdated?(taskState)
        } catch {
            taskState = previous
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
            onTaskUpdated?(taskState)
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
        let normalized = normalizeDate(date)
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        iso.timeZone = TimeZone.current
        return iso.string(from: normalized)
    }

    private func displayDate(_ value: String?) -> String {
        guard let date = parseDate(value) else { return "-" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    @ViewBuilder
    private var editFormContent: some View {
        if horizontalSizeClass == .compact {
            VStack(alignment: .leading, spacing: LLSpacing.md) {
                editBasics
                editStatusPriority
                editSchedule
                editOwnership
                editMeta
            }
        } else {
            HStack(alignment: .top, spacing: LLSpacing.lg) {
                VStack(alignment: .leading, spacing: LLSpacing.md) {
                    editBasics
                    editStatusPriority
                }
                VStack(alignment: .leading, spacing: LLSpacing.md) {
                    editSchedule
                    editOwnership
                    editMeta
                }
            }
        }
    }

    private var editBasics: some View {
        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            Text("Basics")
                .captionText()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            LLTextField(title: "Title", placeholder: "Task title", text: $editTitle)
            LLTextField(title: "Description", placeholder: "Short description", text: $editDescription)
        }
    }

    private var editStatusPriority: some View {
        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            Text("Status & Priority")
                .captionText()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
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
        }
    }

    private var editSchedule: some View {
        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            Text("Schedule")
                .captionText()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            DatePicker("Start date", selection: Binding(get: {
                editStartDate ?? Date()
            }, set: { editStartDate = $0 }), displayedComponents: .date)

            DatePicker("Due date", selection: Binding(get: {
                editDueDate ?? Date()
            }, set: { editDueDate = $0 }), displayedComponents: .date)
        }
    }

    private var editOwnership: some View {
        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            Text("Ownership")
                .captionText()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            Picker("Assignee", selection: $editAssigneeId) {
                Text("Unassigned").tag(Int?.none)
                ForEach(usersViewModel.users) { user in
                    Text(user.username).tag(Int?.some(user.userId))
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var editMeta: some View {
        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            Text("Meta")
                .captionText()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            LLTextField(title: "Tags", placeholder: "ui, backend", text: $editTags)
            LLTextField(title: "Points", placeholder: "0", text: $editPoints)
        }
    }


    private func normalizeDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 12
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? date
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
                            if let imageUrl = comment.imageUrl, let url = URL(string: imageUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 160)
                                            .cornerRadius(10)
                                    case .failure:
                                        Text("Image unavailable")
                                            .bodySmall()
                                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                    default:
                                        ProgressView()
                                    }
                                }
                            }
                            Text(comment.text)
                                .bodyText()
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                        .padding(.vertical, LLSpacing.xs)
                    }
                }

                LLTextField(title: "Add comment", placeholder: "Write a comment", text: $newCommentText)
                if let commentImageUrl, let url = URL(string: commentImageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 140)
                                .cornerRadius(10)
                        default:
                            ProgressView()
                        }
                    }
                }

                if let commentsError = commentsError {
                    InlineErrorView(message: commentsError)
                }

                HStack(spacing: LLSpacing.sm) {
                    LLButton("Add File", style: .outline, size: .sm, isLoading: isUploadingCommentImage, fullWidth: true) {
                        showCommentImagePicker = true
                    }
                    PhotosPicker(selection: $commentPhotoItem, matching: .images) {
                        HStack(spacing: LLSpacing.xs) {
                            Image(systemName: "photo.on.rectangle")
                            Text("Photos")
                                .bodySmall()
                        }
                        .padding(.horizontal, LLSpacing.sm)
                        .padding(.vertical, LLSpacing.xs)
                        .frame(maxWidth: .infinity)
                        .background(LLColors.muted.color(for: colorScheme))
                        .cornerRadius(LLSpacing.radiusMD)
                    }
                }
                .onChange(of: commentPhotoItem) { newItem in
                    guard let newItem else { return }
                    Task { await handlePhotoSelection(newItem) }
                }
                LLButton("Post Comment", style: .secondary, size: .sm, isLoading: isPostingComment, fullWidth: true) {
                    Task { await postComment() }
                }
                LLButton("Clear Image", style: .ghost, size: .sm, fullWidth: true) {
                    commentImageUrl = nil
                }
                .disabled(commentImageUrl == nil)

                if commentImageUrl != nil {
                    Text("Image attached")
                        .bodySmall()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
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
                                let urlString = attachment.presignedUrl ?? attachment.fileURL
                                if let url = URL(string: urlString),
                                   isImageFile(url: url) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(maxHeight: 120)
                                                .cornerRadius(8)
                                        default:
                                            ProgressView()
                                        }
                                    }
                                }
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
        guard !trimmed.isEmpty || commentImageUrl != nil else { return }
        isPostingComment = true
        commentsError = nil
        defer { isPostingComment = false }

        do {
            let created = try await CommentService.shared.createComment(
                taskId: taskState.id,
                text: trimmed.isEmpty ? nil : trimmed,
                imageUrl: commentImageUrl
            )
            comments.insert(created, at: 0)
            newCommentText = ""
            commentImageUrl = nil
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

    private func uploadCommentImage(fileURL: URL) async {
        isUploadingCommentImage = true
        commentsError = nil
        defer { isUploadingCommentImage = false }

        do {
            let uploadedUrl = try await CommentService.shared.uploadCommentImage(fileURL: fileURL)
            commentImageUrl = uploadedUrl
        } catch {
            commentsError = error.localizedDescription
        }
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem) async {
        isUploadingCommentImage = true
        commentsError = nil
        defer { isUploadingCommentImage = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                commentsError = "Unable to read selected photo."
                return
            }
            let filename = "comment-\(UUID().uuidString).jpg"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: tempURL)
            let uploadedUrl = try await CommentService.shared.uploadCommentImage(fileURL: tempURL)
            commentImageUrl = uploadedUrl
        } catch {
            commentsError = error.localizedDescription
        }
    }

    private func isImageFile(url: URL) -> Bool {
        ["png", "jpg", "jpeg", "heic", "gif"].contains(url.pathExtension.lowercased())
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
