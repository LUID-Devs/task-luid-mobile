//
//  MissionControlView.swift
//  TaskLuid
//

import SwiftUI

struct MissionControlView: View {
    @StateObject private var viewModel = MissionControlViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = "Agents"
    @State private var showCreateAgent = false

    var body: some View {
        ScrollView {
            VStack(spacing: LLSpacing.md) {
                headerRow
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
        .background(LLColors.background.color(for: colorScheme))
        .task {
            await viewModel.loadMissionControl()
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == "Tasks" {
                Task { await viewModel.loadAgentTasks() }
            }
        }
        .sheet(isPresented: $showCreateAgent) {
            CreateAgentView { name, displayName, role in
                Task {
                    await viewModel.createAgent(name: name, displayName: displayName, role: role)
                    showCreateAgent = false
                }
            }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            SectionHeaderView("Mission Control", subtitle: "Manage your agents and monitor activity.")
            Spacer()
            if selectedTab == "Agents" {
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
        let pendingTasks = viewModel.agentTasks.filter { $0.status.lowercased() != "completed" }.count

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: LLSpacing.md) {
            StatPillView(title: "Total Agents", value: "\(total)")
            StatPillView(title: "Active Now", value: "\(active)")
            StatPillView(title: "Pending Tasks", value: "\(pendingTasks)")
            StatPillView(title: "Blocked", value: "\(blocked)")
        }
    }

    private var tabPicker: some View {
        Picker("View", selection: $selectedTab) {
            Text("Agents").tag("Agents")
            Text("Tasks").tag("Tasks")
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
            } else if viewModel.agentTasks.isEmpty {
                LLEmptyState(
                    icon: "list.bullet.rectangle",
                    title: "No agent tasks",
                    message: "Assign tasks to agents in the web app."
                )
            } else {
                ForEach(viewModel.agentTasks) { assignment in
                    LLCard(style: .standard) {
                        VStack(alignment: .leading, spacing: LLSpacing.xs) {
                            HStack {
                                Text(assignment.task?.title ?? "Task")
                                    .bodyText()
                                Spacer()
                                LLBadge(assignment.status.capitalized, variant: .outline, size: .sm)
                            }
                            HStack(spacing: LLSpacing.xs) {
                                if let agent = assignment.agent {
                                    Text(agent.displayName)
                                        .captionText()
                                }
                                if let project = assignment.task?.project {
                                    Text("• \(project.name)")
                                        .captionText()
                                }
                            }
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                    }
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
}
