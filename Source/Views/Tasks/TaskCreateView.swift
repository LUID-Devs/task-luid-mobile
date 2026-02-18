//
//  TaskCreateView.swift
//  TaskLuid
//

import SwiftUI

struct TaskCreateView: View {
    struct CreateRequest {
        var title: String
        var description: String?
        var priority: TaskPriority?
        var status: TaskStatus?
        var tags: String?
        var startDate: Date?
        var dueDate: Date?
        var points: String
        var assigneeId: Int?
        var authorUserId: Int?
        var taskType: TaskType?
    }

    let projectId: Int
    let onCreate: (CreateRequest) async -> (TaskItem?, String?)

    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority? = .medium
    @State private var status: TaskStatus? = .toDo
    @State private var tags = ""
    @State private var startDate: Date? = nil
    @State private var dueDate: Date? = nil
    @State private var points = ""
    @State private var assigneeId: Int? = nil
    @State private var authorUserId: Int? = nil
    @State private var taskType: TaskType? = .feature
    @State private var errorMessage: String? = nil
    @State private var isSubmitting = false
    @StateObject private var usersViewModel = UsersViewModel()
    @State private var showAiInput = false
    @State private var aiInput = ""
    @State private var aiError: String? = nil
    @State private var aiNotice: String? = nil
    @State private var isAiParsing = false
    @State private var agents: [Agent] = []
    @State private var assignedAgentId: Int? = nil
    @State private var isAssigningAgent = false
    @State private var showStatusPicker = false
    @State private var showPriorityPicker = false
    @State private var showTypePicker = false
    @State private var showAuthorPicker = false
    @State private var showAssigneePicker = false
    @State private var showAgentPicker = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LLSpacing.md) {
                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        Text("Quick Create with AI")
                            .captionText()
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        LLCard(style: .standard, padding: .sm) {
                            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                                Button {
                                    showAiInput.toggle()
                                } label: {
                                    HStack {
                                        Text("Quick Create with AI")
                                            .bodyText()
                                        Spacer()
                                        Image(systemName: showAiInput ? "chevron.up" : "chevron.down")
                                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())

                                if showAiInput {
                                    LLTextField(title: "AI Input", placeholder: "Describe the task in plain language", text: $aiInput)
                                    LLButton("Parse with AI", style: .outline, size: .sm, isLoading: isAiParsing) {
                                        Task { await parseWithAI() }
                                    }
                                    if let aiNotice {
                                        Text(aiNotice)
                                            .bodySmall()
                                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                    }
                                    if let aiError {
                                        InlineErrorView(message: aiError)
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        Text("Basics")
                            .captionText()
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        LLTextField(title: "Title", placeholder: "Task title", text: $title)
                        LLTextField(title: "Description", placeholder: "Optional description", text: $description)
                    }

                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        Text("Status & Priority")
                            .captionText()
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        selectionRow(
                            title: "Status",
                            value: status?.rawValue ?? "None",
                            action: { showStatusPicker = true }
                        )
                        selectionRow(
                            title: "Priority",
                            value: priority?.rawValue ?? "None",
                            action: { showPriorityPicker = true }
                        )
                    }

                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        Text("Meta")
                            .captionText()
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        selectionRow(
                            title: "Task type",
                            value: taskType?.rawValue ?? "None",
                            action: { showTypePicker = true }
                        )
                        LLTextField(title: "Tags", placeholder: "backend, ui", text: $tags)
                        LLTextField(title: "Points", placeholder: "0", text: $points)
                    }

                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        Text("Schedule")
                            .captionText()
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        DatePicker("Start date", selection: Binding(get: {
                            startDate ?? Date()
                        }, set: { startDate = $0 }), displayedComponents: .date)

                        DatePicker("Due date", selection: Binding(get: {
                            dueDate ?? Date()
                        }, set: { dueDate = $0 }), displayedComponents: .date)
                    }

                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        Text("Ownership")
                            .captionText()
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        selectionRow(
                            title: "Author",
                            value: username(for: authorUserId) ?? "Select author",
                            action: { showAuthorPicker = true }
                        )
                        selectionRow(
                            title: "Assignee",
                            value: username(for: assigneeId) ?? "Unassigned",
                            action: { showAssigneePicker = true }
                        )
                    }

                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        Text("AI Agent")
                            .captionText()
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        selectionRow(
                            title: "Agent",
                            value: agentName(for: assignedAgentId) ?? "Unassigned",
                            action: { showAgentPicker = true }
                        )
                    }

                    if let errorMessage {
                        InlineErrorView(message: errorMessage)
                    }

                    LLButton("Create Task", style: .primary, isLoading: isSubmitting, fullWidth: true) {
                        Task {
                            isSubmitting = true
                            let request = CreateRequest(
                                title: title,
                                description: description.isEmpty ? nil : description,
                                priority: priority,
                                status: status,
                                tags: tags.isEmpty ? nil : tags,
                                startDate: startDate,
                                dueDate: dueDate,
                                points: points,
                                assigneeId: assigneeId,
                                authorUserId: authorUserId,
                                taskType: taskType
                            )
                            let (task, error) = await onCreate(request)
                            errorMessage = error
                            if let task, let agentId = assignedAgentId {
                                isAssigningAgent = true
                                do {
                                    _ = try await MissionControlService.shared.assignTaskToAgents(taskId: task.id, agentIds: [agentId])
                                } catch {
                                    errorMessage = "Task created but failed to assign agent."
                                }
                                isAssigningAgent = false
                            }
                            isSubmitting = false
                            if errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || dueDate == nil || isAssigningAgent)
                }
                .screenPadding()
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .confirmationDialog("Set status", isPresented: $showStatusPicker) {
            Button("None") { status = nil }
            ForEach(TaskStatus.allCases) { option in
                Button(option.rawValue) { status = option }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Set priority", isPresented: $showPriorityPicker) {
            Button("None") { priority = nil }
            ForEach(TaskPriority.allCases) { option in
                Button(option.rawValue) { priority = option }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Set task type", isPresented: $showTypePicker) {
            Button("None") { taskType = nil }
            ForEach(TaskType.allCases) { option in
                Button(option.rawValue) { taskType = option }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Select author", isPresented: $showAuthorPicker) {
            ForEach(usersViewModel.users) { user in
                Button(user.username) { authorUserId = user.userId }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Select assignee", isPresented: $showAssigneePicker) {
            Button("Unassigned") { assigneeId = nil }
            ForEach(usersViewModel.users) { user in
                Button(user.username) { assigneeId = user.userId }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Select AI agent", isPresented: $showAgentPicker) {
            Button("Unassigned") { assignedAgentId = nil }
            ForEach(agents) { agent in
                Button(agent.displayName) { assignedAgentId = agent.id }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            Task { await usersViewModel.loadUsers() }
            Task { await loadAgents() }
            if authorUserId == nil, let userId = KeychainManager.shared.getUserId(), let parsed = Int(userId) {
                authorUserId = parsed
            }
        }
    }

    private func selectionRow(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .bodySmall()
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                Spacer()
                Text(value)
                    .bodyText()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
            .padding(.horizontal, LLSpacing.sm)
            .padding(.vertical, LLSpacing.xs)
            .background(LLColors.muted.color(for: colorScheme))
            .cornerRadius(LLSpacing.radiusMD)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func username(for userId: Int?) -> String? {
        guard let userId else { return nil }
        return usersViewModel.users.first { $0.userId == userId }?.username
    }

    private func agentName(for agentId: Int?) -> String? {
        guard let agentId else { return nil }
        return agents.first { $0.id == agentId }?.displayName
    }

    private func loadAgents() async {
        do {
            agents = try await MissionControlService.shared.getAgents()
        } catch {
            agents = []
        }
    }

    private func parseWithAI() async {
        let trimmed = aiInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            aiError = "AI input is required."
            return
        }

        aiError = nil
        aiNotice = nil
        isAiParsing = true
        defer { isAiParsing = false }

        do {
            let teamMembers = usersViewModel.users.map(\.username)
            let response = try await AIService.shared.parseTask(text: trimmed, teamMembers: teamMembers)
            guard response.success == true, let parsed = response.data else {
                aiError = response.error?.message ?? "Failed to parse task."
                return
            }

            if let parsedTitle = parsed.title, !parsedTitle.isEmpty { title = parsedTitle }
            if let parsedDescription = parsed.description { description = parsedDescription }
            if let parsedPriority = parsed.priority, let mapped = TaskPriority(rawValue: parsedPriority) {
                priority = mapped
            }
            if let parsedTags = parsed.tags { tags = parsedTags }
            if let parsedAssignee = parsed.assignee, let match = usersViewModel.users.first(where: {
                $0.username.lowercased() == parsedAssignee.lowercased()
            }) {
                assigneeId = match.userId
            }
            if let parsedDueDate = parsed.dueDate, let date = parseISODate(parsedDueDate) {
                dueDate = date
            }

            aiNotice = "Task parsed. Review fields before creating."
        } catch {
            aiError = error.localizedDescription
        }
    }

    private func parseISODate(_ value: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: value) {
            return date
        }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: value)
    }
}
