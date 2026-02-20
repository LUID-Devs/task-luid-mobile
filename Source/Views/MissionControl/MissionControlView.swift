//
//  MissionControlView.swift
//  TaskLuid
//

import SwiftUI

struct MissionControlView: View {
    @StateObject private var viewModel = MissionControlViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = "Agents"
    @State private var showCreateAgent = false
    @State private var selectedTask: TaskItem? = nil
    @State private var isLoadingTaskDetail = false
    @State private var taskDetailError: String? = nil
    @State private var isPollingEnabled = false

    private let agentPollTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    private let activityPollTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    private let tasksPollTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private let taskColumns: [MissionTaskColumn] = [
        MissionTaskColumn(id: "inbox", title: "Inbox", color: .gray),
        MissionTaskColumn(id: "assigned", title: "Assigned", color: .blue),
        MissionTaskColumn(id: "in_progress", title: "In Progress", color: .yellow),
        MissionTaskColumn(id: "review", title: "Review", color: .purple),
        MissionTaskColumn(id: "completed", title: "Done", color: .green),
    ]

    private let priorityColors: [String: Color] = [
        "urgent": .red,
        "high": .orange,
        "medium": .yellow,
        "low": .gray
    ]

    private let agentEmojis: [String: String] = [
        "mr-krabs": "🦀",
        "spongebob": "🧽",
        "squidward": "🦑",
        "sandy": "🐿️",
        "karen": "🖥️",
        "patrick": "⭐",
        "plankton": "🦠",
        "gary": "🐌",
        "mrs-puff": "🐡",
        "mermaid-man": "🦸"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: LLSpacing.md) {
                headerRow
                welcomeCard
                statsRow
                tabPicker

                if viewModel.isLoading {
                    LLLoadingView("Loading mission control...")
                } else if let errorMessage = viewModel.errorMessage {
                    InlineErrorView(message: errorMessage)
                } else {
                    switch selectedTab {
                    case "Agents":
                        agentsSection
                    case "Tasks":
                        tasksSection
                    default:
                        activitySection
                    }
                }
            }
            .screenPadding()
        }
        .appBackground()
        .task {
            await viewModel.loadMissionControl()
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == "Tasks" {
                Task { await viewModel.loadAgentTasks() }
            }
        }
        .onAppear {
            isPollingEnabled = true
        }
        .onDisappear {
            isPollingEnabled = false
        }
        .onReceive(agentPollTimer) { _ in
            guard isPollingEnabled else { return }
            Task { await viewModel.refreshAgents() }
        }
        .onReceive(activityPollTimer) { _ in
            guard isPollingEnabled else { return }
            Task { await viewModel.refreshActivity() }
        }
        .onReceive(tasksPollTimer) { _ in
            guard isPollingEnabled, selectedTab == "Tasks" else { return }
            Task { await viewModel.refreshAgentTasks() }
        }
        .sheet(isPresented: $showCreateAgent) {
            CreateAgentView { name, displayName, role in
                Task {
                    await viewModel.createAgent(name: name, displayName: displayName, role: role)
                    showCreateAgent = false
                }
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task) { updated in
                selectedTask = updated
                Task { await viewModel.refreshAgentTasks() }
            }
        }
        .alert("Task Load Failed", isPresented: Binding(get: {
            taskDetailError != nil
        }, set: { _ in
            taskDetailError = nil
        })) {
            Button("OK") { taskDetailError = nil }
        } message: {
            Text(taskDetailError ?? "Unable to load task.")
        }
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            SectionHeaderView("Mission Control", subtitle: "Manage your agents and monitor activity.")
            Spacer()
            if selectedTab == "Agents", viewModel.canManageAgents {
                Button {
                    showCreateAgent = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))
                }
            }
        }
    }

    private var statsRow: some View {
        let total = viewModel.agents.count
        let active = viewModel.agents.filter { $0.status.lowercased() == "active" }.count
        let blocked = viewModel.agents.filter { $0.status.lowercased() == "blocked" }.count
        let idle = viewModel.agents.filter { $0.status.lowercased() == "idle" }.count
        let pendingTasks = viewModel.agents.reduce(0) { $0 + ( $1.count?.assignedTasks ?? 0 ) }
        let unreadNotifications = viewModel.agents.reduce(0) { $0 + ( $1.count?.notifications ?? 0 ) }

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: LLSpacing.md) {
            missionStatCard(
                title: "Total Agents",
                value: "\(total)",
                subtitle: "Squad overview"
            )
            missionStatCard(
                title: "Active Now",
                value: "\(active)",
                subtitle: "\(idle) idle, \(blocked) blocked"
            )
            missionStatCard(
                title: "Pending Tasks",
                value: "\(pendingTasks)",
                subtitle: "Across all agents"
            )
            missionStatCard(
                title: "Notifications",
                value: "\(unreadNotifications)",
                subtitle: "Unread mentions"
            )
        }
    }

    private var tabPicker: some View {
        Picker("View", selection: $selectedTab) {
            Text("Agents (\(viewModel.agents.count))").tag("Agents")
            Text("Tasks (\(viewModel.agentTasks.count))").tag("Tasks")
            Text("Activity").tag("Activity")
        }
        .pickerStyle(SegmentedPickerStyle())
    }

    private var agentsSection: some View {
        VStack(spacing: LLSpacing.md) {
            if viewModel.agents.isEmpty {
                LLEmptyState(
                    icon: "sparkles",
                    title: "No agents yet",
                    message: "Create agents in the web app to see them here."
                )
            } else {
                ForEach(viewModel.agents) { agent in
                    LLCard(style: .standard) {
                        HStack(spacing: LLSpacing.sm) {
                            Circle()
                                .fill(LLColors.muted.color(for: colorScheme))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(String(agent.displayName.prefix(1)).uppercased())
                                        .h4()
                                )

                            VStack(alignment: .leading, spacing: LLSpacing.xs) {
                                Text(agent.displayName)
                                    .h4()
                                Text(agent.role)
                                    .bodySmall()
                                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                            }

                            Spacer()

                            LLBadge(agent.status.capitalized, variant: badgeVariant(for: agent.status), size: .sm)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteAgent(agentId: agent.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    private var activitySection: some View {
        VStack(spacing: LLSpacing.md) {
            if viewModel.activity.isEmpty {
                LLEmptyState(
                    icon: "waveform.path.ecg",
                    title: "No activity yet",
                    message: "Agent activity will appear here."
                )
            } else {
                ForEach(viewModel.activity) { log in
                    LLCard(style: .standard) {
                        VStack(alignment: .leading, spacing: LLSpacing.xs) {
                            Text(log.agent.displayName)
                                .bodyText()
                            Text(log.action.replacingOccurrences(of: "_", with: " ").capitalized)
                                .captionText()
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                            if let task = log.task {
                                Text(task.title)
                                    .bodySmall()
                            }
                        }
                    }
                }
            }
        }
    }

    private var tasksSection: some View {
        VStack(spacing: LLSpacing.md) {
            if viewModel.isLoadingTasks {
                LLLoadingView("Loading agent tasks...")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LLSpacing.md) {
                        ForEach(taskColumns) { column in
                            missionTaskColumn(column)
                                .frame(width: 280)
                        }
                    }
                    .padding(.vertical, LLSpacing.xs)
                }
            }
        }
    }

    private func badgeVariant(for status: String) -> LLBadgeVariant {
        switch status.lowercased() {
        case "active":
            return .success
        case "blocked":
            return .warning
        default:
            return .outline
        }
    }

    private var welcomeCard: some View {
        let activeCount = viewModel.agents.filter { $0.status.lowercased() == "active" }.count
        let name = authViewModel.user?.username ?? authViewModel.user?.email ?? "Commander"
        return LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.xs) {
                Text("Welcome to Mission Control, \(name)!")
                    .h4()
                Text("Monitor your AI agent squad, track tasks, and view real-time activity.")
                    .bodySmall()
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                if activeCount > 0 {
                    Text("\(activeCount) agent\(activeCount == 1 ? "" : "s") currently active.")
                        .captionText()
                        .foregroundColor(LLColors.success.color(for: colorScheme))
                }
            }
        }
    }

    private func missionStatCard(title: String, value: String, subtitle: String) -> some View {
        LLCard(style: .standard) {
            VStack(alignment: .leading, spacing: LLSpacing.xs) {
                Text(title)
                    .captionText()
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                Text(value)
                    .h3()
                Text(subtitle)
                    .captionText()
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
        }
    }

    private func missionTaskColumn(_ column: MissionTaskColumn) -> some View {
        let tasks = tasksForColumn(column.id)
        return VStack(alignment: .leading, spacing: LLSpacing.sm) {
            HStack(spacing: LLSpacing.xs) {
                Circle()
                    .fill(column.color)
                    .frame(width: 10, height: 10)
                Text(column.title)
                    .bodySmall()
                    .lineLimit(1)
                Spacer()
                LLBadge("\(tasks.count)", variant: .outline, size: .sm)
            }

            ScrollView {
                VStack(spacing: LLSpacing.sm) {
                    if tasks.isEmpty {
                        LLCard(style: .standard) {
                            Text("No tasks")
                                .bodySmall()
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, LLSpacing.md)
                        }
                    } else {
                        ForEach(tasks) { assignment in
                            LLCard(style: .standard) {
                                VStack(alignment: .leading, spacing: LLSpacing.xs) {
                                    Text(assignment.task?.title ?? "Task")
                                        .bodyText()
                                        .lineLimit(2)
                                    if let projectName = assignment.task?.project?.name {
                                        Text(projectName)
                                            .captionText()
                                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                    }
                                    HStack {
                                        if let priority = assignment.task?.priority?.lowercased() {
                                            Text(priority.capitalized)
                                                .font(LLTypography.caption())
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(priorityColors[priority, default: .yellow].opacity(0.15))
                                                .foregroundColor(priorityColors[priority, default: .yellow])
                                                .cornerRadius(8)
                                        }
                                        Spacer()
                                        if let agentName = assignment.agent?.name {
                                            Text(agentEmojis[agentName] ?? "🤖")
                                        } else {
                                            Text("🤖")
                                        }
                                    }
                                }
                            }
                            .onTapGesture {
                                Task { await loadTaskDetail(taskId: assignment.taskId) }
                            }
                        }
                    }
                }
                .padding(.trailing, LLSpacing.xs)
            }
            .frame(height: 380)
        }
    }

    private func tasksForColumn(_ columnId: String) -> [AgentTaskAssignment] {
        viewModel.agentTasks.filter { $0.status.lowercased() == columnId }
    }

    private func loadTaskDetail(taskId: Int) async {
        guard !isLoadingTaskDetail else { return }
        isLoadingTaskDetail = true
        defer { isLoadingTaskDetail = false }

        do {
            let task = try await TaskService.shared.getTask(id: taskId)
            selectedTask = task
        } catch {
            taskDetailError = error.localizedDescription
        }
    }
}

private struct MissionTaskColumn: Identifiable {
    let id: String
    let title: String
    let color: Color
}
